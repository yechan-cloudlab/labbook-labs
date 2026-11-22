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
  s3_use_path_style           = var.use_emulator

  default_tags {
    tags = var.tags
  }

  endpoints {
    dynamodb = var.aws_endpoint_url
    ec2      = var.aws_endpoint_url
    iam      = var.aws_endpoint_url
    lambda   = var.aws_endpoint_url
    logs     = var.aws_endpoint_url
    s3       = var.aws_endpoint_url
    sqs      = var.aws_endpoint_url
    sts      = var.aws_endpoint_url
  }
}

# Minimal security group (no ingress rules, uses region's default VPC)
resource "aws_security_group" "probe" {
  name        = "${var.name_prefix}-sg"
  description = "Minimal SG for region creation probe (no ingress)"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

# Empty S3 bucket with unique prefix and force_destroy
resource "aws_s3_bucket" "probe" {
  bucket_prefix = "${var.name_prefix}-"
  force_destroy = true
}

resource "aws_sqs_queue" "probe" {
  name = "${var.name_prefix}-queue"
}

resource "aws_dynamodb_table" "probe" {
  name         = "${var.name_prefix}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-lambda-role"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "probe" {
  name              = "/aws/lambda/${var.name_prefix}-fn"
  retention_in_days = 1
}

resource "aws_lambda_function" "probe" {
  function_name    = "${var.name_prefix}-fn"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = "${path.module}/dist/python-handler.zip"
  source_code_hash = filebase64sha256("${path.module}/dist/python-handler.zip")
  memory_size      = var.lambda_memory_size
  timeout          = 10
  description      = "Minimal region probe Lambda (128 MB)"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_cloudwatch_log_group.probe,
  ]
}
