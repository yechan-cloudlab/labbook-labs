variable "aws_region" {
  description = "AWS region to deploy into (override to ap-southeast-2 on KR Free-plan accounts with SCP region restrictions)."
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "labbook-sm-vpconly"
}

variable "corp_ip_cidrs" {
  description = "Example corporate public IPv4 CIDRs (RFC 5737 documentation ranges by default)."
  type        = list(string)
  default     = ["192.0.2.0/24", "203.0.113.0/24"]
}

variable "create_vpc_endpoints" {
  description = "Whether to create SageMaker API & Studio Interface VPC Endpoints (~$0.01/hr per AZ per endpoint)."
  type        = bool
  default     = true
}

variable "create_sagemaker_domain" {
  description = "Whether to create the SageMaker Studio Domain (IAM auth, VpcOnly) and user profile."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "labbook-labs"
    Lab       = "sagemaker-presigned-url-ip-vpc"
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
