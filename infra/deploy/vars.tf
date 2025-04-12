variable "prefix" {
  description = "Prefix for AWS resources to distinguish this stack"
  default     = "recipe-api-"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "devops-recipe-app-api"
}

variable "contact" {
  description = "github user to contact for questions about this stack"
  default     = "phonewrites"
}