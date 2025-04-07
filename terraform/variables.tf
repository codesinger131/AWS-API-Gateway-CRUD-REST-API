variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
  default     = "terraform-Coffee-Shop"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)"
  default     = "dev"
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket to store the Terraform state securely"
  default     = "my-terraform-state-bucket"  # Change this to your bucket name
}

variable "state_lock_table" {
  type        = string
  description = "DynamoDB table for Terraform state locking"
  default     = "my-terraform-lock-table"     # Change this to your lock table name
}
