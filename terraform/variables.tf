variable "bucket_name" {
  description = "S3 bucket for storing API data"
  type        = string
}

variable "lambda_role_name" {
  description = "IAM role name for Lambda"
  type        = string
  default     = "lambda_execution_role"
}
