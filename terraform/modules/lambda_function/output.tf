output "lambda_invoke_arn" {
  description = "Invoke ARN of the created Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}