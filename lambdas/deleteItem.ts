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

    await dynamo
      .delete({
        TableName: DYNAMO_TABLE,
        Key: { id },
      })
      .promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Item deleted successfully' }),
    };
  } catch (error) {
    console.error('Error deleting item:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error' }),
    };
  }
};
