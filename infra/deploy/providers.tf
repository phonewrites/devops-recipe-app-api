data "aws_region" "current" {}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }
  # Terraform state backend configuration
  backend "s3" {
    bucket               = "tf-state-nvirginia-961341515801"
    dynamodb_table       = "terraform-state-locks"
    encrypt              = true
    key                  = "terraform-state-setup"
    workspace_key_prefix = "terraform-state-deploy"
    profile              = "mgmt"
    region               = "us-east-1"
  }
}

provider "aws" {
  # profile = "mgmt"
  region = "us-east-1"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
      #   managed_by    = "Terraform/deploy"
    }
  }
}