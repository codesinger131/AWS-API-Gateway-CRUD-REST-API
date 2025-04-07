resource "aws_lambda_function" "this" {
  function_name = var.function_name
  handler       = var.handler
  role          = var.role_arn
  runtime       = "nodejs16.x"
  filename      = var.archive_path
  timeout       = 10

  environment {
    variables = var.environment
  }
}

