provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "raw_data" {
  bucket = "event-pipeline-raw-data"
  force_destroy = true
}

resource "aws_s3_bucket" "report_bucket" {
  bucket = "event-pipeline-report-bucket"
  force_destroy = true
}

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

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "ingest_lambda" {
  function_name = "IngestLambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambda_ingest/index.zip"
}

resource "aws_lambda_function" "report_lambda" {
  function_name = "ReportLambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambda_daily_report/index.zip"
}

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name        = "daily-lambda-trigger"
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
