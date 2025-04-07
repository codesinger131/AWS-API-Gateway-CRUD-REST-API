import { handler } from '../deleteItem';
import AWS from 'aws-sdk';
import { APIGatewayProxyEvent, Context } from 'aws-lambda';

// Mock the AWS SDK
jest.mock('aws-sdk', () => {
  const mDocumentClient = { delete: jest.fn().mockReturnThis(), promise: jest.fn() };
  return { DynamoDB: { DocumentClient: jest.fn(() => mDocumentClient) } };
});

const mDynamoDb = new AWS.DynamoDB.DocumentClient();

describe('Delete Item Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 if path parameter "id" is missing', async () => {
    const event = { pathParameters: null } as APIGatewayProxyEvent;
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body).message).toBe('Missing path parameter "id"');
  });

  it('should return 200 and delete item successfully', async () => {
    const event = { pathParameters: { id: '123' } } as unknown as APIGatewayProxyEvent;
    mDynamoDb.delete().promise.mockResolvedValueOnce({});
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(200);
    expect(JSON.parse(result.body).message).toBe('Item deleted successfully');
    expect(mDynamoDb.delete).toHaveBeenCalledWith({
      TableName: process.env.DYNAMO_TABLE,
      Key: { id: '123' },
    });
  });

  it('should return 500 if DynamoDB delete operation fails', async () => {
    const event = { pathParameters: { id: '123' } } as unknown as APIGatewayProxyEvent;
    mDynamoDb.delete().promise.mockRejectedValueOnce(new Error('DynamoDB error'));
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body).message).toBe('Internal server error');
  });
});
