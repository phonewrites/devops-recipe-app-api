data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }
  # Terraform state backend configuration in mgmt account
  backend "s3" {
    bucket         = "tf-state-nvirginia-961341515801"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    key            = "terraform-state-setup"
    profile        = "mgmt"
    region         = "us-east-1"
  }
}

# Default aws provider set to be mgmt account 
provider "aws" {
  # profile = "mgmt"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
      #   managed_by    = "Terraform/setup"
    }
  }
}

provider "aws" {
  profile = "prod"
  alias   = "prod"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
      #   managed_by    = "Terraform/setup"
    }
  }
}



