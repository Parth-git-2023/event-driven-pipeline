output "s3_raw_data_bucket" {
  value = aws_s3_bucket.raw_data.bucket
}

output "lambda_ingest_name" {
  value = aws_lambda_function.ingest_lambda.function_name
}
