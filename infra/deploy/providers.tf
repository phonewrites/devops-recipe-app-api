data "aws_region" "current" {}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
  # Terraform state backend configuration in mgmt account
  backend "s3" {
    profile              = "mgmt"
    bucket               = "tf-state-nvirginia-961341515801"
    dynamodb_table       = "terraform-state-locks"
    encrypt              = true
    key                  = "devops-recipe-app-api/infra/deploy/tf.state"
    workspace_key_prefix = "devops-recipe-app-api/infra/deploy/workspace"
    region               = "us-east-1"
  }
}

provider "aws" {
  profile = "prod"
  region  = "us-east-1"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
      #   managed_by    = "Terraform/deploy"
    }
  }
}
provider "aws" {
  profile = "mgmt"
  alias   = "mgmt"
  region  = "us-east-1"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
      #   managed_by    = "Terraform/setup"
    }
  }
}