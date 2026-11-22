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
    ec2 = var.aws_endpoint_url
    iam = var.aws_endpoint_url
    sns = var.aws_endpoint_url
    sqs = var.aws_endpoint_url
    sts = var.aws_endpoint_url
  }
}

resource "aws_vpc" "this" {
  count                = var.create_vpc_endpoint ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_subnet" "this" {
  count             = var.create_vpc_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.name_prefix}-subnet"
  }
}

resource "aws_security_group" "vpce" {
  count       = var.create_vpc_endpoint ? 1 : 0
  name        = "${var.name_prefix}-vpce-sg"
  description = "Minimal SG for SQS Interface VPC Endpoint (allow HTTPS from VPC CIDR)"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
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

resource "aws_iam_role" "app" {
  name = "${var.name_prefix}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_sqs_queue" "orders" {
  name = "${var.name_prefix}-orders"
}

resource "aws_sns_topic" "orders" {
  name = "${var.name_prefix}-orders-topic"
}

locals {
  vpce_id = var.create_vpc_endpoint ? aws_vpc_endpoint.sqs[0].id : "vpce-0123456789abcdef0"
}

resource "aws_vpc_endpoint" "sqs" {
  count               = var.create_vpc_endpoint ? 1 : 0
  vpc_id              = aws_vpc.this[0].id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.this[0].id]
  security_group_ids  = [aws_security_group.vpce[0].id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.app.arn }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = aws_sqs_queue.orders.arn
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-sqs-vpce"
  }
}

# Safe SQS queue policy:
# - Denies message actions outside the specified VPCE only when the request is NOT from an AWS service principal
#   and NOT forwarded via an AWS service (FAS), using BoolIfExists so anonymous callers are still denied.
# - Avoids blocking sqs:SetQueueAttributes / sqs:DeleteQueue so administrators do not lock themselves out.
resource "aws_sqs_queue_policy" "safe" {
  queue_url = aws_sqs_queue.orders.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAppRole"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.app.arn }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.orders.arn
      },
      {
        Sid       = "AllowSnsTopic"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.orders.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_sns_topic.orders.arn
          }
        }
      },
      {
        Sid       = "DenyMessageActionsOutsideVpce"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.orders.arn
        Condition = {
          StringNotEquals = {
            "aws:SourceVpce" = local.vpce_id
          }
          BoolIfExists = {
            "aws:PrincipalIsAWSService" = "false"
            "aws:ViaAWSService"         = "false"
          }
        }
      }
    ]
  })
}
