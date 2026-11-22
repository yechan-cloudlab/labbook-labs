output "vpc_id" {
  description = "ID of the VPC created for SageMaker Studio VpcOnly."
  value       = aws_vpc.this.id
}

output "sagemaker_domain_id" {
  description = "SageMaker Studio domain ID (null if create_sagemaker_domain = false)."
  value       = var.create_sagemaker_domain ? aws_sagemaker_domain.this[0].id : null
}

output "sagemaker_user_profile_name" {
  description = "SageMaker Studio user profile name."
  value       = var.create_sagemaker_domain ? aws_sagemaker_user_profile.demo[0].user_profile_name : null
}

output "vpce_ids" {
  description = "API and Studio Interface VPC Endpoint IDs."
  value       = var.create_vpc_endpoints ? [aws_vpc_endpoint.sagemaker_api[0].id, aws_vpc_endpoint.sagemaker_studio[0].id] : []
}

output "iam_policy_arns" {
  description = "ARNs of the standalone IAM condition policy examples."
  value = {
    allow_corp_ip     = aws_iam_policy.allow_corp_ip.arn
    allow_vpce        = aws_iam_policy.allow_vpce.arn
    allow_vpc_subnet  = aws_iam_policy.allow_vpc_subnet.arn
    deny_outside_vpce = aws_iam_policy.deny_outside_vpce.arn
  }
}
