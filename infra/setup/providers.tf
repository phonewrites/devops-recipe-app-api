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
    bucket       = "terraform-state-993249607057-us-east-1"
    use_lockfile = true
    encrypt      = true
    key          = "devops-recipe-app-api/setup/terraform.tfstate"
    region       = "us-east-1"
    profile      = "mgmt"
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
    }
  }
}

# aws provider alias set for prod account 
provider "aws" {
  profile = "prod"
  alias   = "prod"
  region  = "us-east-1"
  default_tags {
    tags = {
      environment = terraform.workspace
      project     = var.project
      contact     = var.contact
    }
  }
}



