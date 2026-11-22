variable "aws_region" {
  description = "AWS region to deploy into (default ap-southeast-2 for KR Free-plan compatibility)."
  type        = string
  default     = "ap-southeast-2"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "labbook-coldstart"
}

variable "lambda_memory_size" {
  description = "Memory size in MB for all functions (128 MB default per cost policy; set 512 to match the blog post's cross-runtime comparison)."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout in seconds for all functions."
  type        = number
  default     = 15
}

variable "enable_vpc" {
  description = "Whether to create the VPC-attached Python Lambda (uses default VPC subnets + SG, no NAT/ALB)."
  type        = bool
  default     = true
}

variable "enable_snapstart" {
  description = "Whether to create SnapStart-enabled Python and Java functions (publishes version 1)."
  type        = bool
  default     = true
}

variable "enable_java" {
  description = "Whether to create Java 21 functions."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "labbook-labs"
    Lab       = "lambda-cold-start-arm-snapstart-vpc"
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
