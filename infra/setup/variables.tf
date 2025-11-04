data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# S3 bucket is created+managed outside Terraform
variable "tf_state_bucket" {
  description = "Name of S3 bucket in AWS for storing TF state"
  default     = "tf-state-nvirginia-961341515801"
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