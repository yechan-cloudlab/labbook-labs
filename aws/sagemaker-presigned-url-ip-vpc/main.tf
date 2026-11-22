terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = var.use_emulator ? "testing" : null
  secret_key                  = var.use_emulator ? "testing" : null
  skip_credentials_validation = var.use_emulator
  skip_metadata_api_check     = var.use_emulator
  skip_requesting_account_id  = var.use_emulator
  skip_region_validation      = var.use_emulator

  default_tags {
    tags = var.tags
  }

  endpoints {
    ec2       = var.aws_endpoint_url
    iam       = var.aws_endpoint_url
    sagemaker = var.aws_endpoint_url
    sts       = var.aws_endpoint_url
  }
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.name_prefix}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.name_prefix}-private-b"
  }
}

# Security group meeting SageMaker Studio VpcOnly requirements (self 8192-65535 + NFS 2049)
resource "aws_security_group" "studio" {
  name        = "${var.name_prefix}-studio-sg"
  description = "SageMaker Studio VpcOnly security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SageMaker Studio inter-app TCP"
    from_port   = 8192
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "NFS for Studio EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-studio-sg"
  }
}

resource "aws_security_group" "vpce" {
  count       = var.create_vpc_endpoints ? 1 : 0
  name        = "${var.name_prefix}-vpce-sg"
  description = "Interface VPC Endpoint SG for SageMaker API and Studio"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpce-sg"
  }
}

resource "aws_iam_role" "studio_exec" {
  name = "${var.name_prefix}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sagemaker.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_sagemaker_domain" "this" {
  count                   = var.create_sagemaker_domain ? 1 : 0
  domain_name             = "${var.name_prefix}-domain"
  auth_mode               = "IAM"
  app_network_access_type = "VpcOnly"
  vpc_id                  = aws_vpc.this.id
  subnet_ids              = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  default_user_settings {
    execution_role  = aws_iam_role.studio_exec.arn
    security_groups = [aws_security_group.studio.id]
  }
}

resource "aws_sagemaker_user_profile" "demo" {
  count             = var.create_sagemaker_domain ? 1 : 0
  domain_id         = aws_sagemaker_domain.this[0].id
  user_profile_name = "data-scientist-1"
}

locals {
  studio_endpoint_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "sagemaker:CreateApp"
        Resource  = var.create_sagemaker_domain ? "${aws_sagemaker_domain.this[0].arn}/*" : "*"
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "sagemaker:CreatePresignedDomainUrl"
        Resource  = var.create_sagemaker_domain ? "${aws_sagemaker_user_profile.demo[0].arn}" : "*"
      }
    ]
  })

  vpce_ids = var.create_vpc_endpoints ? [
    aws_vpc_endpoint.sagemaker_api[0].id,
    aws_vpc_endpoint.sagemaker_studio[0].id,
  ] : ["vpce-0aaa1111bbbb22223", "vpce-0ccc3333dddd44445"]
}

resource "aws_vpc_endpoint" "sagemaker_api" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
  private_dns_enabled = true
  policy              = local.studio_endpoint_policy

  tags = {
    Name = "${var.name_prefix}-api-vpce"
  }
}

resource "aws_vpc_endpoint" "sagemaker_studio" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "aws.sagemaker.${var.aws_region}.studio"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.vpce[0].id]
  private_dns_enabled = true
  policy              = local.studio_endpoint_policy

  tags = {
    Name = "${var.name_prefix}-studio-vpce"
  }
}

# Example standalone IAM identity policies (not attached to the caller to avoid self-lockout).
resource "aws_iam_policy" "allow_corp_ip" {
  name        = "${var.name_prefix}-allow-corp-ip"
  description = "Allow CreatePresignedDomainUrl only from corporate public IP ranges (aws:SourceIp)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStudioFromCorpIp"
        Effect = "Allow"
        Action = [
          "sagemaker:CreatePresignedDomainUrl",
          "sagemaker:DescribeUserProfile",
        ]
        Resource = "*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.corp_ip_cidrs
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "allow_vpce" {
  name        = "${var.name_prefix}-allow-vpce"
  description = "Allow CreatePresignedDomainUrl only via API and Studio VPC endpoints (aws:SourceVpce)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStudioFromVpce"
        Effect = "Allow"
        Action = [
          "sagemaker:CreatePresignedDomainUrl",
          "sagemaker:DescribeUserProfile",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = local.vpce_ids
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "allow_vpc_subnet" {
  name        = "${var.name_prefix}-allow-vpc-subnet"
  description = "Allow CreatePresignedDomainUrl from a specific VPC subnet using VpcSourceIp + SourceVpc."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStudioFromVpcSubnet"
        Effect = "Allow"
        Action = [
          "sagemaker:CreatePresignedDomainUrl",
          "sagemaker:DescribeUserProfile",
        ]
        Resource = "*"
        Condition = {
          IpAddress = {
            "aws:VpcSourceIp" = aws_subnet.private_a.cidr_block
          }
          StringEquals = {
            "aws:SourceVpc" = aws_vpc.this.id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "deny_outside_vpce" {
  name        = "${var.name_prefix}-deny-outside-vpce"
  description = "Explicitly deny CreatePresignedDomainUrl outside the specified VPC endpoints."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyPresignedUrlOutsideVpce"
        Effect   = "Deny"
        Action   = "sagemaker:CreatePresignedDomainUrl"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:SourceVpce" = local.vpce_ids
          }
        }
      }
    ]
  })
}
