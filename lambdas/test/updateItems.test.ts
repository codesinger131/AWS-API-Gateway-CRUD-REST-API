import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamo = new AWS.DynamoDB.DocumentClient();
const { DYNAMO_TABLE = '' } = process.env;

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const { id } = event.pathParameters || {};

    if (!id) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Missing path parameter "id"' }),
      };
    }

    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Missing request body' }),
      };
    }

    const body = JSON.parse(event.body);
    if (!body.name) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Request body must contain "name"' }),
      };
    }

    const updated = await dynamo
      .update({
        TableName: DYNAMO_TABLE,
        Key: { id },
        UpdateExpression: 'SET #nm = :nm',
        ExpressionAttributeNames: {
          '#nm': 'name',
        },
        ExpressionAttributeValues: {
          ':nm': body.name,
        },
        ReturnValues: 'ALL_NEW',
      })
      .promise();

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Item updated successfully',
        item: updated.Attributes,
      }),
    };
  } catch (error) {
    console.error('Error updating item:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error' }),
    };
  }
};
