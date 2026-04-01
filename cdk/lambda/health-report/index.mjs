import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';

const ddb = new DynamoDBClient({});

export const handler = async (event) => {
  const userId = event.requestContext?.authorizer?.claims?.sub;
  const report = JSON.parse(event.body || '{}');

  const { date, steps, sleepHours, heartRate, hrv, restingHR, aiAdvice, savedAt } = report;

  if (!date) return response(400, { error: 'date is required' });

  await ddb.send(new PutItemCommand({
    TableName: process.env.TABLE_NAME,
    Item: {
      PK:          { S: `USER#${userId}` },
      SK:          { S: `REPORT#${date}` },
      steps:       { N: String(steps ?? 0) },
      sleepHours:  { N: String(sleepHours ?? 0) },
      heartRate:   { N: String(heartRate ?? 0) },
      hrv:         { N: String(hrv ?? 0) },
      restingHR:   { N: String(restingHR ?? 0) },
      aiAdvice:    { S: aiAdvice ?? '' },
      savedAt:     { S: savedAt ?? new Date().toISOString() },
    },
  }));

  return response(200, { success: true });
};

const response = (statusCode, body) => ({
  statusCode,
  headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  body: JSON.stringify(body),
});
