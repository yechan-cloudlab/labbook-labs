output "sqs_queue_url" {
  description = "URL of the test SQS queue."
  value       = aws_sqs_queue.orders.url
}

output "sqs_queue_arn" {
  description = "ARN of the test SQS queue."
  value       = aws_sqs_queue.orders.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic permitted by the queue policy."
  value       = aws_sns_topic.orders.arn
}

output "app_role_arn" {
  description = "ARN of the sample application IAM role."
  value       = aws_iam_role.app.arn
}

output "sqs_vpc_endpoint_id" {
  description = "ID of the SQS Interface VPC Endpoint (null if create_vpc_endpoint = false)."
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.sqs[0].id : null
}
