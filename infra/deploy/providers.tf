terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta3"
    }
  }
  # Terraform state backend configuration in mgmt account
  backend "s3" {
    bucket               = "tf-state-nvirginia-961341515801"
    dynamodb_table       = "terraform-state-locks"
    encrypt              = true
    key                  = "devops-recipe-app-api/deploy-state"
    workspace_key_prefix = "devops-recipe-app-api/workspace"
    region               = "us-east-1"
    assume_role = {
      role_arn = "arn:aws:iam::961341515801:role/tf-backend-access-role"
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
