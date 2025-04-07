import { handler } from '../createItem'; 
import AWS from 'aws-sdk';
import { APIGatewayProxyEvent, Context } from 'aws-lambda';

// Mock the AWS SDK
jest.mock('aws-sdk', () => {
  const mDocumentClient = { put: jest.fn().mockReturnThis(), promise: jest.fn() };
  return { DynamoDB: { DocumentClient: jest.fn(() => mDocumentClient) } };
});

const mDynamoDb = new AWS.DynamoDB.DocumentClient();

describe('Lambda Function Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 if request body is missing', async () => {
    const event = { body: null } as APIGatewayProxyEvent;
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body).message).toBe('Missing request body');
  });

  it('should return 400 if id or name is missing in request body', async () => {
    const event = { body: JSON.stringify({ id: '123' }) } as APIGatewayProxyEvent;
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body).message).toBe('Request body must contain "id" and "name"');
  });

  it('should return 201 and create item successfully', async () => {
    const event = { body: JSON.stringify({ id: '123', name: 'Test Item' }) } as APIGatewayProxyEvent;
    mDynamoDb.put().promise.mockResolvedValueOnce({});
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(201);
    expect(JSON.parse(result.body).message).toBe('Item created successfully');
    expect(mDynamoDb.put).toHaveBeenCalledWith({
      TableName: process.env.DYNAMO_TABLE,
      Item: { id: '123', name: 'Test Item' },
    });
  });

  it('should return 500 if DynamoDB put operation fails', async () => {
    const event = { body: JSON.stringify({ id: '123', name: 'Test Item' }) } as APIGatewayProxyEvent;
    mDynamoDb.put().promise.mockRejectedValueOnce(new Error('DynamoDB error'));
    const result = await handler(event, {} as Context);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body).message).toBe('Internal server error');
  });
});
