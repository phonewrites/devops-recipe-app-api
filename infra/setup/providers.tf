data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
  # Terraform state backend configuration in mgmt account
  backend "s3" {
    profile        = "mgmt"
    bucket         = "tf-state-nvirginia-961341515801"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    key            = "devops-recipe-app-api/infra/setup/tf.state"
    region         = "us-east-1"
  }
}

# Default aws provider set to be mgmt account 
provider "aws" {
  profile = "mgmt"
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

provider "aws" {
  profile = "prod"
  alias   = "prod"
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



