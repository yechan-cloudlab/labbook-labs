output "function_names" {
  description = "Map of configuration key to deployed Lambda function name."
  value       = { for k, fn in aws_lambda_function.fn : k => fn.function_name }
}

output "published_versions" {
  description = "Published version per function (SnapStart functions publish version 1; others stay $LATEST)."
  value       = { for k, fn in aws_lambda_function.fn : k => fn.version }
}

output "lambda_memory_size" {
  description = "Configured memory size in MB for all functions."
  value       = var.lambda_memory_size
}
