data "archive_file" "fetch_public_api_zip" {
  type        = "zip"
  source_file = "../lambda/fetch_public_api.py"
  output_path = "${path.module}/fetch_public_api.zip"
}

data "archive_file" "daily_summary_zip" {
  type        = "zip"
  source_file = "../lambda/daily_summary.py"
  output_path = "${path.module}/daily_summary.zip"
}

############################
# S3 BUCKET
############################
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.bucket_name
}

############################
# IAM ROLE FOR LAMBDA
############################
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

############################
# IAM POLICIES FOR LAMBDA
############################
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

############################
# LAMBDA: FETCH PUBLIC API
############################
resource "aws_lambda_function" "fetch_public_api" {
  function_name = "fetch-public-api-data"
  runtime       = "python3.10"
  handler       = "fetch_public_api.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.fetch_public_api_zip.output_path
  source_code_hash = data.archive_file.fetch_public_api_zip.output_base64sha256

  timeout = 30

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
    }
  }
}



############################
# LAMBDA: DAILY SUMMARY REPORT
############################
resource "aws_lambda_function" "daily_summary" {
  function_name = "daily-summary-report"
  runtime       = "python3.10"
  handler       = "daily_summary.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.daily_summary_zip.output_path
  source_code_hash = data.archive_file.daily_summary_zip.output_base64sha256

  timeout = 60

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
    }
  }
}

