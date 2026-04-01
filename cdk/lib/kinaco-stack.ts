import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigw from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import * as path from 'path';

export class KinaCoStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ─── Cognito ───────────────────────────────────────────────
    const userPool = new cognito.UserPool(this, 'KinaCoUserPool', {
      userPoolName: 'kinaco-user-pool',
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      passwordPolicy: {
        minLength: 8,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    const userPoolClient = new cognito.UserPoolClient(this, 'KinaCoUserPoolClient', {
      userPool,
      authFlows: { userPassword: true, userSrp: true },
      generateSecret: false,
    });

    // ─── DynamoDB ──────────────────────────────────────────────
    // PK: USER#<sub>
    // SK:
    //   REPORT#2026-03-28  日次バイタル＋AI診断
    //   TRAIT#CORE         長期傾向（キナコが更新）
    //   MSG#<timestamp>    チャット履歴
    const table = new dynamodb.Table(this, 'KinaCoTable', {
      tableName: 'kinaco-health',
      partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
      sortKey:      { name: 'SK', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      timeToLiveAttribute: 'ttl', // MSG履歴は自動削除可能に
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // ─── Lambda 共通設定 ───────────────────────────────────────
    const lambdaEnv = {
      TABLE_NAME: table.tableName,
      USER_POOL_ID: userPool.userPoolId,
      BEDROCK_MODEL_ID: 'anthropic.claude-3-sonnet-20240229-v1:0',
      BEDROCK_REGION: 'us-east-1', // Bedrockはus-east-1が安定
    };

    const bedrockPolicy = new iam.PolicyStatement({
      actions: ['bedrock:InvokeModel'],
      resources: ['arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0'],
    });

    // ─── Lambda: chat（体調管理秘書） ──────────────────────────
    const chatFn = new lambda.Function(this, 'ChatFunction', {
      functionName: 'kinaco-chat',
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/chat')),
      environment: lambdaEnv,
      timeout: cdk.Duration.seconds(30),
    });
    chatFn.addToRolePolicy(bedrockPolicy);
    table.grantReadWriteData(chatFn);

    // ─── Lambda: health/analyze（バイタル解析） ────────────────
    const analyzeFn = new lambda.Function(this, 'AnalyzeFunction', {
      functionName: 'kinaco-health-analyze',
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/health-analyze')),
      environment: lambdaEnv,
      timeout: cdk.Duration.seconds(30),
    });
    analyzeFn.addToRolePolicy(bedrockPolicy);
    table.grantReadWriteData(analyzeFn);

    // ─── Lambda: health/report（レポート保存） ─────────────────
    const reportFn = new lambda.Function(this, 'ReportFunction', {
      functionName: 'kinaco-health-report',
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/health-report')),
      environment: lambdaEnv,
      timeout: cdk.Duration.seconds(10),
    });
    table.grantReadWriteData(reportFn);

    // ─── Lambda: health/reports（レポート一覧取得） ────────────
    const reportsFn = new lambda.Function(this, 'ReportsFunction', {
      functionName: 'kinaco-health-reports',
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/health-reports')),
      environment: lambdaEnv,
      timeout: cdk.Duration.seconds(10),
    });
    table.grantReadData(reportsFn);

    // ─── Cognito Authorizer ────────────────────────────────────
    const authorizer = new apigw.CognitoUserPoolsAuthorizer(this, 'KinaCoAuthorizer', {
      cognitoUserPools: [userPool],
      authorizerName: 'kinaco-authorizer',
    });

    const authOptions: apigw.MethodOptions = {
      authorizer,
      authorizationType: apigw.AuthorizationType.COGNITO,
    };

    // ─── API Gateway ───────────────────────────────────────────
    const api = new apigw.RestApi(this, 'KinaCoApi', {
      restApiName: 'kinaco-api',
      defaultCorsPreflightOptions: {
        allowOrigins: apigw.Cors.ALL_ORIGINS,
        allowMethods: apigw.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    // POST /chat
    api.root
      .addResource('chat')
      .addMethod('POST', new apigw.LambdaIntegration(chatFn), authOptions);

    // /health
    const health = api.root.addResource('health');

    // POST /health/analyze
    health.addResource('analyze')
      .addMethod('POST', new apigw.LambdaIntegration(analyzeFn), authOptions);

    // POST /health/report
    health.addResource('report')
      .addMethod('POST', new apigw.LambdaIntegration(reportFn), authOptions);

    // GET /health/reports
    health.addResource('reports')
      .addMethod('GET', new apigw.LambdaIntegration(reportsFn), authOptions);

    // ─── Outputs ───────────────────────────────────────────────
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      description: 'API Gateway URL → Configuration.xcconfig の KINACOAPI_URL に設定',
    });
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
      description: 'Cognito User Pool ID',
    });
    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'Cognito Client ID → Configuration.xcconfig の COGNITO_CLIENT_ID に設定',
    });
  }
}
