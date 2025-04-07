

terraform {
   backend "s3" {
    bucket         = var.state_bucket
    key            = "${var.project_name}/${var.environment}/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = var.state_lock_table
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}




resource "aws_dynamodb_table" "items_table" {
  name         = "${var.project_name}-table-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}


# 3. IAM Role for Lambda

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Environment = var.environment
  }
}


# 4. IAM Policies for DynamoDB & Logs

# DynamoDB
data "aws_iam_policy_document" "lambda_dynamodb_policy" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.items_table.arn]
  }
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${var.project_name}-lambda-dynamodb-policy-${var.environment}"
  policy      = data.aws_iam_policy_document.lambda_dynamodb_policy.json
  description = "Policy for Lambda to access DynamoDB"
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# CloudWatch Logs
data "aws_iam_policy_document" "lambda_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "${var.project_name}-lambda-logging-policy-${var.environment}"
  policy      = data.aws_iam_policy_document.lambda_logging_policy.json
  description = "Policy for Lambda logging to CloudWatch"
}

resource "aws_iam_role_policy_attachment" "attach_logging_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}



# 5. Create Lambda Functions via Module

# We reference local.*_zip_output_path from lambda-archive.tf
module "create_item_lambda" {
  source       = "./modules/lambda_function"
  function_name = "${var.project_name}-createItem-${var.environment}"
  handler       = "dist/lambdas/createItem.handler"
  role_arn      = aws_iam_role.lambda_role.arn
  archive_path  = local.create_item_zip_output_path

  environment = {
    DYNAMO_TABLE = aws_dynamodb_table.items_table.name
  }
}

module "get_item_lambda" {
  source       = "./modules/lambda_function"
  function_name = "${var.project_name}-getItem-${var.environment}"
  handler       = "dist/lambdas/getItem.handler"
  role_arn      = aws_iam_role.lambda_role.arn
  archive_path  = local.get_item_zip_output_path

  environment = {
    DYNAMO_TABLE = aws_dynamodb_table.items_table.name
  }
}

module "update_item_lambda" {
  source       = "./modules/lambda_function"
  function_name = "${var.project_name}-updateItem-${var.environment}"
  handler       = "dist/lambdas/updateItem.handler"
  role_arn      = aws_iam_role.lambda_role.arn
  archive_path  = local.update_item_zip_output_path

  environment = {
    DYNAMO_TABLE = aws_dynamodb_table.items_table.name
  }
}

module "delete_item_lambda" {
  source       = "./modules/lambda_function"
  function_name = "${var.project_name}-deleteItem-${var.environment}"
  handler       = "dist/lambdas/deleteItem.handler"
  role_arn      = aws_iam_role.lambda_role.arn
  archive_path  = local.delete_item_zip_output_path

  environment = {
    DYNAMO_TABLE = aws_dynamodb_table.items_table.name
  }
}


#  API Gateway

resource "aws_api_gateway_rest_api" "crud_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "CRUD API"
}

# /items
resource "aws_api_gateway_resource" "items_resource" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  parent_id   = aws_api_gateway_rest_api.crud_api.root_resource_id
  path_part   = "items"
}

# /items/{id}
resource "aws_api_gateway_resource" "item_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  parent_id   = aws_api_gateway_resource.items_resource.id
  path_part   = "{id}"
}

# POST /items  CreateItem
resource "aws_api_gateway_method" "post_items" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.items_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_items_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.items_resource.id
  http_method             = aws_api_gateway_method.post_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.create_item_lambda.lambda_invoke_arn
}

# GET /items/{id} -> GetItem
resource "aws_api_gateway_method" "get_item" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.item_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.item_id_resource.id
  http_method             = aws_api_gateway_method.get_item.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = module.get_item_lambda.lambda_invoke_arn
}

# 6c. PUT /items/{id} -> UpdateItem
resource "aws_api_gateway_method" "put_item" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.item_id_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "put_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.item_id_resource.id
  http_method             = aws_api_gateway_method.put_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.update_item_lambda.lambda_invoke_arn
}

# 6d. DELETE /items/{id} -> DeleteItem
resource "aws_api_gateway_method" "delete_item" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.item_id_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.item_id_resource.id
  http_method             = aws_api_gateway_method.delete_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.delete_item_lambda.lambda_invoke_arn
}




resource "aws_api_gateway_deployment" "crud_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.post_items_integration,
    aws_api_gateway_integration.get_item_integration,
    aws_api_gateway_integration.put_item_integration,
    aws_api_gateway_integration.delete_item_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  stage_name  = var.environment
}
