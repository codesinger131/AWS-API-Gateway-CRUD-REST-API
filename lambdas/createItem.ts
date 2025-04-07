import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamo = new AWS.DynamoDB.DocumentClient();
const { DYNAMO_TABLE = '' } = process.env;

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Missing request body' }),
      };
    }

    const body = JSON.parse(event.body);
    const { id, name } = body;

    if (!id || !name) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body must contain "id" and "name"',
        }),
      };
    }

    await dynamo
      .put({
        TableName: DYNAMO_TABLE,
        Item: { id, name },
      })
      .promise();

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: 'Item created successfully',
        item: { id, name },
      }),
    };
  } catch (error) {
    console.error('Error creating item:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error' }),
    };
  }
};
