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
    sts = var.aws_endpoint_url
  }
}

resource "aws_vpc" "inspection" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-inspection"
  }
}

resource "aws_subnet" "az_a" {
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.name_prefix}-az-a"
  }
}

resource "aws_subnet" "az_b" {
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.name_prefix}-az-b"
  }
}

resource "aws_ec2_transit_gateway" "this" {
  description = "LabBook Transit Gateway appliance mode lab"

  tags = {
    Name = "${var.name_prefix}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  subnet_ids                                      = [aws_subnet.az_a.id, aws_subnet.az_b.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = aws_vpc.inspection.id
  appliance_mode_support                          = var.appliance_mode_support
  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name = "${var.name_prefix}-inspection-attachment"
  }
}
