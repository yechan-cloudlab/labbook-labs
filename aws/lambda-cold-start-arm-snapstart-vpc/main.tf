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
    ec2    = var.aws_endpoint_url
    iam    = var.aws_endpoint_url
    lambda = var.aws_endpoint_url
    logs   = var.aws_endpoint_url
    sts    = var.aws_endpoint_url
  }
}

data "aws_vpc" "default" {
  count   = var.enable_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.enable_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

resource "aws_security_group" "lambda_vpc" {
  count       = var.enable_vpc ? 1 : 0
  name        = "${var.name_prefix}-vpc-sg"
  description = "Minimal SG for VPC-attached Lambda (no ingress, no NAT)"
  vpc_id      = data.aws_vpc.default[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpc-sg"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  count      = var.enable_vpc ? 1 : 0
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

locals {
  py_zip   = "${path.module}/dist/python-handler.zip"
  java_zip = "${path.module}/dist/java-handler.zip"

  functions = merge(
    {
      "py312-x86-novpc" = {
        runtime       = "python3.12"
        handler       = "index.handler"
        architectures = ["x86_64"]
        zip_path      = local.py_zip
        vpc           = false
        snapstart     = false
      }
      "py312-arm-novpc" = {
        runtime       = "python3.12"
        handler       = "index.handler"
        architectures = ["arm64"]
        zip_path      = local.py_zip
        vpc           = false
        snapstart     = false
      }
    },
    var.enable_vpc ? {
      "py312-x86-vpc" = {
        runtime       = "python3.12"
        handler       = "index.handler"
        architectures = ["x86_64"]
        zip_path      = local.py_zip
        vpc           = true
        snapstart     = false
      }
    } : {},
    var.enable_snapstart ? {
      "py312-x86-snapstart" = {
        runtime       = "python3.12"
        handler       = "index.handler"
        architectures = ["x86_64"]
        zip_path      = local.py_zip
        vpc           = false
        snapstart     = true
      }
    } : {},
    var.enable_java ? {
      "java21-x86-novpc-nosnap" = {
        runtime       = "java21"
        handler       = "example.Handler::handleRequest"
        architectures = ["x86_64"]
        zip_path      = local.java_zip
        vpc           = false
        snapstart     = false
      }
    } : {},
    (var.enable_java && var.enable_snapstart) ? {
      "java21-x86-snapstart" = {
        runtime       = "java21"
        handler       = "example.Handler::handleRequest"
        architectures = ["x86_64"]
        zip_path      = local.java_zip
        vpc           = false
        snapstart     = true
      }
    } : {},
  )
}

resource "aws_cloudwatch_log_group" "fn" {
  for_each          = local.functions
  name              = "/aws/lambda/${var.name_prefix}-${each.key}"
  retention_in_days = 1
}

resource "aws_lambda_function" "fn" {
  for_each         = local.functions
  function_name    = "${var.name_prefix}-${each.key}"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = each.value.runtime
  handler          = each.value.handler
  architectures    = each.value.architectures
  filename         = each.value.zip_path
  source_code_hash = filebase64sha256(each.value.zip_path)
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  publish          = each.value.snapstart

  dynamic "vpc_config" {
    for_each = each.value.vpc ? [1] : []
    content {
      subnet_ids         = slice(sort(data.aws_subnets.default[0].ids), 0, min(2, length(data.aws_subnets.default[0].ids)))
      security_group_ids = [aws_security_group.lambda_vpc[0].id]
    }
  }

  dynamic "snap_start" {
    for_each = each.value.snapstart ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic,
    aws_iam_role_policy_attachment.vpc,
    aws_cloudwatch_log_group.fn,
  ]
}
