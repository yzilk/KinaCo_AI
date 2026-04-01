import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { DynamoDBClient, PutItemCommand, QueryCommand } from '@aws-sdk/client-dynamodb';

const bedrock = new BedrockRuntimeClient({ region: process.env.BEDROCK_REGION });
const ddb = new DynamoDBClient({});

const SYSTEM_PROMPT = `あなたは「キナコ」という名前の体調管理秘書AIです。
ユーザーのバイタルデータ（歩数・睡眠・心拍数・HRV）を把握した上で、
健康的な生活をサポートする温かく的確なアドバイスをします。
返答は日本語で、簡潔かつ親しみやすいトーンで答えてください。`;

export const handler = async (event) => {
  const userId = event.requestContext?.authorizer?.claims?.sub;
  const body = JSON.parse(event.body || '{}');
  const userMessage = body.message || '';

  if (!userMessage) {
    return response(400, { error: 'message is required' });
  }

  // 直近のREPORTとMSGを取得してコンテキストに含める
  const history = await fetchRecentContext(userId);

  const messages = [
    ...history,
    { role: 'user', content: userMessage },
  ];

  const reply = await invokeClauде(messages);

  // チャット履歴をDDBに保存（TTL: 30日）
  const now = Date.now();
  const ttl = Math.floor(now / 1000) + 60 * 60 * 24 * 30;
  await ddb.send(new PutItemCommand({
    TableName: process.env.TABLE_NAME,
    Item: {
      PK: { S: `USER#${userId}` },
      SK: { S: `MSG#${now}` },
      role: { S: 'user' },
      content: { S: userMessage },
      ttl: { N: String(ttl) },
    },
  }));
  await ddb.send(new PutItemCommand({
    TableName: process.env.TABLE_NAME,
    Item: {
      PK: { S: `USER#${userId}` },
      SK: { S: `MSG#${now + 1}` },
      role: { S: 'assistant' },
      content: { S: reply },
      ttl: { N: String(ttl) },
    },
  }));

  return response(200, { reply });
};

async function fetchRecentContext(userId) {
  const messages = [];

  // 直近7日のREPORTを取得
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const fromDate = sevenDaysAgo.toISOString().split('T')[0];

  const reportRes = await ddb.send(new QueryCommand({
    TableName: process.env.TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :from AND :to',
    ExpressionAttributeValues: {
      ':pk': { S: `USER#${userId}` },
      ':from': { S: `REPORT#${fromDate}` },
      ':to': { S: 'REPORT#9999' },
    },
    Limit: 7,
    ScanIndexForward: false,
  }));

  if (reportRes.Items?.length) {
    const reportSummary = reportRes.Items.map(item =>
      `${item.SK.S?.replace('REPORT#', '')}の記録: 歩数${item.steps?.N}歩, 睡眠${item.sleepHours?.N}h, 心拍${item.heartRate?.N}bpm`
    ).join('\n');
    messages.push({ role: 'user', content: `【過去のバイタル記録】\n${reportSummary}` });
    messages.push({ role: 'assistant', content: 'バイタル記録を確認しました。何かご相談はありますか？' });
  }

  // TRAIT#COREがあれば追加
  const traitRes = await ddb.send(new QueryCommand({
    TableName: process.env.TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND SK = :sk',
    ExpressionAttributeValues: {
      ':pk': { S: `USER#${userId}` },
      ':sk': { S: 'TRAIT#CORE' },
    },
  }));
  if (traitRes.Items?.[0]?.traits?.S) {
    messages.push({ role: 'user', content: `【あなたの傾向】\n${traitRes.Items[0].traits.S}` });
    messages.push({ role: 'assistant', content: 'あなたの傾向を把握しています。' });
  }

  // 直近10件のMSGを取得
  const msgRes = await ddb.send(new QueryCommand({
    TableName: process.env.TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
    ExpressionAttributeValues: {
      ':pk': { S: `USER#${userId}` },
      ':prefix': { S: 'MSG#' },
    },
    Limit: 10,
    ScanIndexForward: false,
  }));
  const recentMsgs = (msgRes.Items || []).reverse();
  for (const item of recentMsgs) {
    messages.push({ role: item.role.S, content: item.content.S });
  }

  return messages;
}

async function invokeClauде(messages) {
  const payload = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 1024,
    system: SYSTEM_PROMPT,
    messages,
  };
  const cmd = new InvokeModelCommand({
    modelId: process.env.BEDROCK_MODEL_ID,
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(payload),
  });
  const res = await bedrock.send(cmd);
  const result = JSON.parse(Buffer.from(res.body).toString());
  return result.content?.[0]?.text ?? 'うまく返答できませんでした';
}

const response = (statusCode, body) => ({
  statusCode,
  headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  body: JSON.stringify(body),
});
