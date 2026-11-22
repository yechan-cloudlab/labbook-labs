variable "aws_region" {
  description = "AWS region to deploy into (override to ap-southeast-2 on KR Free-plan accounts with SCP region restrictions)."
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "labbook-tgw-appliance"
}

variable "appliance_mode_support" {
  description = "Transit Gateway VPC attachment appliance mode support (enable or disable)."
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.appliance_mode_support)
    error_message = "appliance_mode_support must be \"enable\" or \"disable\"."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the inspection VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "labbook-labs"
    Lab       = "transit-gateway-appliance-mode"
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
