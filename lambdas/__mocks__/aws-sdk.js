const mDocumentClient = {
    delete: jest.fn().mockReturnThis(),
    promise: jest.fn(),
  };
  
  const DynamoDB = {
    DocumentClient: jest.fn(() => mDocumentClient),
  };
  
  module.exports = { DynamoDB };
  