variable "aws_region" {
  description = "AWS region to deploy into (default ap-southeast-2 for KR Free-plan compatibility)."
  type        = string
  default     = "ap-southeast-2"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "labbook-ec2-ipv4"
}

variable "instance_type" {
  description = "EC2 instance type. Defaults to t4g.nano (minimal ARM64 spec per cost policy)."
  type        = string
  default     = "t4g.nano"
}

variable "allocate_eip" {
  description = "Whether to allocate and associate an Elastic IP (set false first to test auto-assigned IPv4 release, then true to observe EIP retention when stopped)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "labbook-labs"
    Lab       = "ec2-stop-public-ipv4-eip-charge"
    ManagedBy = "terraform"
  }
}

variable "use_emulator" {
  description = "Set true when targeting a local emulator (moto) to skip AWS credential/account checks."
  type        = bool
  default     = false
}

variable "aws_endpoint_url" {
  description = "Optional custom endpoint URL (e.g., http://127.0.0.1:5000 for moto). Leave null for real AWS."
  type        = string
  default     = null
}
