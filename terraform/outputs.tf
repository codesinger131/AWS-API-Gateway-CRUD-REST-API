# outputs.tf

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.items_table.name
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.crud_api.id
}

output "api_deployment_invoke_url" {
  description = "Base invoke URL for the REST API"
  value       = aws_api_gateway_deployment.crud_api_deployment.invoke_url
}
