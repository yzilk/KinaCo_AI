import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';

const ddb = new DynamoDBClient({});

export const handler = async (event) => {
  const userId = event.requestContext?.authorizer?.claims?.sub;

  // 直近30日分を取得
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const fromDate = thirtyDaysAgo.toISOString().split('T')[0];

  const res = await ddb.send(new QueryCommand({
    TableName: process.env.TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :from AND :to',
    ExpressionAttributeValues: {
      ':pk':   { S: `USER#${userId}` },
      ':from': { S: `REPORT#${fromDate}` },
      ':to':   { S: 'REPORT#9999' },
    },
    ScanIndexForward: false, // 新しい順
  }));

  const reports = (res.Items || []).map(item => ({
    date:       item.SK.S?.replace('REPORT#', ''),
    steps:      Number(item.steps?.N ?? 0),
    sleepHours: Number(item.sleepHours?.N ?? 0),
    heartRate:  Number(item.heartRate?.N ?? 0),
    hrv:        Number(item.hrv?.N ?? 0),
    restingHR:  Number(item.restingHR?.N ?? 0),
    aiAdvice:   item.aiAdvice?.S ?? '',
    savedAt:    item.savedAt?.S ?? '',
  }));

  return response(200, reports);
};

const response = (statusCode, body) => ({
  statusCode,
  headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  body: JSON.stringify(body),
});
