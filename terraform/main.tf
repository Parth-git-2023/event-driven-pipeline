provider "aws" {
  region = "us-east-1"
}

# 🔹 Create S3 buckets
resource "aws_s3_bucket" "raw_data" {
  bucket = "event-pipeline-raw-data"
  force_destroy = true
}

resource "aws_s3_bucket" "report_bucket" {
  bucket = "event-pipeline-report-bucket"
  force_destroy = true
}

# 🔹 IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 🔹 IAM Policy: Allow Lambda to write to S3
resource "aws_iam_policy" "lambda_s3_access" {
  name = "lambda-s3-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::event-pipeline-raw-data",
          "arn:aws:s3:::event-pipeline-raw-data/*",
          "arn:aws:s3:::event-pipeline-report-bucket",
          "arn:aws:s3:::event-pipeline-report-bucket/*"
        ]
      }
    ]
  })
}

# 🔹 Attach policy to the Lambda role
resource "aws_iam_policy_attachment" "lambda_s3_access_attach" {
  name       = "lambda-s3-access-attachment"
  policy_arn = aws_iam_policy.lambda_s3_access.arn
  roles      = [aws_iam_role.lambda_exec_role.name]
}

# 🔹 Lambda Function 1 - Ingest
resource "aws_lambda_function" "ingest_lambda" {
  function_name = "IngestLambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambda_ingest/index.zip"
}

# 🔹 Lambda Function 2 - Daily Report
resource "aws_lambda_function" "report_lambda" {
  function_name = "ReportLambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambda_daily_report/index.zip"
}

# 🔹 Daily Trigger for Report Lambda
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily-lambda-trigger"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "DailyLambda"
  arn       = aws_lambda_function.report_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}
