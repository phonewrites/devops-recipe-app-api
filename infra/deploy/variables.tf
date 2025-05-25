data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  prefix = "recipe-api-${terraform.workspace}"
}

# AWS Default Resource tags
variable "project" {
  description = "Project name for tagging resources"
  default     = "devops-recipe-app-api"
}
variable "contact" {
  description = "github user to contact for questions about this stack"
  default     = "phonewrites"
}

variable "db_username" {
  description = "Username for the recipe app api database"
  default     = "recipeappdbuser"
}
variable "db_password" {
  description = "Password for the Terraform database"
}
variable "ecr_app_image" {
  description = "Path to the ECR repo with the API image"
}
variable "ecr_proxy_image" {
  description = "Path to the ECR repo with the proxy image"
}
variable "django_secret_key" {
  description = "Secret key for Django"
}

variable "custom_domain" {
  description = "Your Route53 hosted zone name (e.g. example.com)"
  type        = string
}
variable "subdomain" {
  description = "Subdomain for each environment"
  type        = map(string)
  default = {
    prod    = "recipe.api"
    staging = "recipe.api.staging"
    dev     = "recipe.api.dev"
  }
}