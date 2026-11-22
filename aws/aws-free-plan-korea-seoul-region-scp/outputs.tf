output "region" {
  description = "Target region used for this probe."
  value       = var.aws_region
}

output "security_group_id" {
  description = "Created security group ID."
  value       = aws_security_group.probe.id
}

output "s3_bucket_name" {
  description = "Created S3 bucket name."
  value       = aws_s3_bucket.probe.id
}

output "sqs_queue_url" {
  description = "Created SQS queue URL."
  value       = aws_sqs_queue.probe.url
}

output "dynamodb_table_name" {
  description = "Created DynamoDB table name."
  value       = aws_dynamodb_table.probe.name
}

output "lambda_function_name" {
  description = "Created Lambda function name."
  value       = aws_lambda_function.probe.function_name
}
