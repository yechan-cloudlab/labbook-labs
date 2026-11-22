output "transit_gateway_id" {
  description = "ID of the Transit Gateway."
  value       = aws_ec2_transit_gateway.this.id
}

output "inspection_vpc_id" {
  description = "ID of the inspection VPC."
  value       = aws_vpc.inspection.id
}

output "attachment_id" {
  description = "ID of the inspection VPC Transit Gateway attachment."
  value       = aws_ec2_transit_gateway_vpc_attachment.inspection.id
}

output "appliance_mode_support" {
  description = "Configured ApplianceModeSupport value on the VPC attachment."
  value       = aws_ec2_transit_gateway_vpc_attachment.inspection.appliance_mode_support
}
