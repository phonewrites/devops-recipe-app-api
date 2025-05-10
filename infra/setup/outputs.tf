#########################################################
# Outputs for ECR repositories for app and proxy images #
#########################################################

output "ecr_repo_app_uri" {
  description = "ECR repository URL for app image"
  value       = aws_ecr_repository.recipe_app_api_app.repository_url
}
output "ecr_repo_proxy_uri" {
  description = "ECR repository URL for the proxy image"
  value       = aws_ecr_repository.recipe_app_api_proxy.repository_url
}