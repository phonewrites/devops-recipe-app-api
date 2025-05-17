data "aws_availability_zones" "available" {
  state = "available"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "devops-recipe-app-api"
}

variable "contact" {
  description = "github user to contact for questions about this stack"
  default     = "phonewrites"
}