data "aws_availability_zones" "available" {
  state = "available"
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
  default     = "recipeapp-db-user"
}
variable "db_password" {
  description = "Password for the Terraform database"
}