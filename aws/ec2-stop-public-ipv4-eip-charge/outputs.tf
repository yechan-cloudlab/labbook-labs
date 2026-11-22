output "instance_id" {
  description = "ID of the test EC2 instance."
  value       = aws_instance.this.id
}

output "instance_type" {
  description = "Instance type used (default t4g.nano)."
  value       = aws_instance.this.instance_type
}

output "auto_or_current_public_ip" {
  description = "Initial public IP reported by the instance resource."
  value       = aws_instance.this.public_ip
}

output "eip_public_ip" {
  description = "Allocated Elastic IP (null if allocate_eip = false)."
  value       = var.allocate_eip ? aws_eip.this[0].public_ip : null
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP (null if allocate_eip = false)."
  value       = var.allocate_eip ? aws_eip.this[0].id : null
}
