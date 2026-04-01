import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { DynamoDBClient, PutItemCommand, GetItemCommand } from '@aws-sdk/client-dynamodb';

const bedrock = new BedrockRuntimeClient({ region: process.env.BEDROCK_REGION });
const ddb = new DynamoDBClient({});

const ANALYZE_PROMPT = `あなたは体調管理AIのキナコです。
以下のバイタルデータを分析して、日本語で3〜4文の簡潔なアドバイスをしてください。
数値の良し悪しを判断し、改善点や褒める点を具体的に伝えてください。`;

export const handler = async (event) => {
  const userId = event.requestContext?.authorizer?.claims?.sub;
  const healthData = JSON.parse(event.body || '{}');

  const { steps, sleep_hours, heart_rate, hrv, resting_hr, timestamp } = healthData;

  // Bedrockでアドバイス生成
  const prompt = `${ANALYZE_PROMPT}

バイタルデータ:
- 歩数: ${steps}歩
- 睡眠時間: ${sleep_hours}時間
- 心拍数: ${heart_rate}bpm
- HRV: ${hrv}ms
- 安静時心拍数: ${resting_hr}bpm`;

  const advice = await invokeClauде(prompt);

  // TRAIT#COREを更新（長期傾向をAIが判断）
  await updateTrait(userId, healthData);

  return response(200, { advice });
};

async function updateTrait(userId, healthData) {
  // 既存のTRAITを取得
  const existing = await ddb.send(new GetItemCommand({
    TableName: process.env.TABLE_NAME,
    Key: {
      PK: { S: `USER#${userId}` },
      SK: { S: 'TRAIT#CORE' },
    },
  }));

  const currentTraits = existing.Item?.traits?.S || '';

  // 簡易的な傾向更新（歩数・睡眠の平均傾向）
  const steps = Number(healthData.steps);
  const sleep = Number(healthData.sleep_hours);
  let traits = currentTraits;

  if (steps < 3000) traits = traits.includes('運動不足傾向') ? traits : traits + ' 運動不足傾向';
  if (sleep < 6) traits = traits.includes('睡眠不足傾向') ? traits : traits + ' 睡眠不足傾向';
  if (steps > 8000) traits = traits.includes('活動的') ? traits : traits + ' 活動的';

  await ddb.send(new PutItemCommand({
    TableName: process.env.TABLE_NAME,
    Item: {
      PK: { S: `USER#${userId}` },
      SK: { S: 'TRAIT#CORE' },
      traits: { S: traits.trim() },
      updatedAt: { S: new Date().toISOString() },
    },
  }));
}

async function invokeClauде(prompt) {
  const payload = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 512,
    messages: [{ role: 'user', content: prompt }],
  };
  const cmd = new InvokeModelCommand({
    modelId: process.env.BEDROCK_MODEL_ID,
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(payload),
  });
  const res = await bedrock.send(cmd);
  const result = JSON.parse(Buffer.from(res.body).toString());
  return result.content?.[0]?.text ?? '分析できませんでした';
}

const response = (statusCode, body) => ({
  statusCode,
  headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  body: JSON.stringify(body),
});
