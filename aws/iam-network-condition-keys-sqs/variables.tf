variable "aws_region" {
  description = "AWS region to deploy into (override to ap-southeast-2 on KR Free-plan accounts with SCP region restrictions)."
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "labbook-sqs-net"
}

variable "create_vpc_endpoint" {
  description = "Whether to create an SQS Interface VPC Endpoint (~$0.01/hr). Set false for a zero-cost queue/policy-only test."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for the minimal test VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the test subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "labbook-labs"
    Lab       = "iam-network-condition-keys-sqs"
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
