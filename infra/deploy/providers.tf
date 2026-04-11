terraform {
  required_version = ">= 1.14.8, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.39.0"
    }
  }
  # Terraform state backend configuration in mgmt account
  backend "s3" {
    bucket               = "terraform-state-993249607057-us-east-1"
    use_lockfile         = true
    encrypt              = true
    key                  = "devops-recipe-app-api/terraform.tfstate"
    workspace_key_prefix = "devops-recipe-app-api"
    region               = "us-east-1"
    assume_role = {
      role_arn = "arn:aws:iam::993249607057:role/tf-backend-access-role"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
    }
  }
}
