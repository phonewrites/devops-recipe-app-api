# S3 bucket & DynamoDB table are created+managed outside Terraform
variable "tf_state_bucket" {
  description = "Name of S3 bucket in AWS for storing TF state"
  default     = "tf-state-nvirginia-961341515801"
}
variable "tf_state_lock_table" {
  description = "Name of DynamoDB table for TF state locking"
  default     = "terraform-state-locks"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "devops-recipe-app-api"
}

variable "contact" {
  description = "github user to contact for questions about this stack"
  default     = "phonewrites"
}