variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "handler" {
  type        = string
  description = "Handler in <filename>.<function> format"
}

variable "role_arn" {
  type        = string
  description = "IAM Role ARN that Lambda will assume"
}

variable "archive_path" {
  type        = string
  description = "Path to the zipped artifact for the Lambda code"
}

variable "environment" {
  type        = map(string)
  default     = {}
  description = "Environment variables for Lambda"
}