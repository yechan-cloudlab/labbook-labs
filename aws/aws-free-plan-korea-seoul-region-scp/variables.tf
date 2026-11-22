variable "aws_region" {
  description = "Target AWS region. Default is ap-southeast-2 (allowed on KR Free-plan accounts); set ap-northeast-2 to test SCP denial."
  type        = string
  default     = "ap-southeast-2"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "labbook-region-probe"
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB (128 MB minimum default)."
  type        = number
  default     = 128
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "labbook-labs"
    Lab       = "aws-free-plan-korea-seoul-region-scp"
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
