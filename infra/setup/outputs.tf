#########################################################
# Outputs for the CD user's access key and secret key   #
#########################################################
output "cd_user_access_key_id" {
  description = "Access key ID for CD user"
  value       = aws_iam_access_key.cd_user_access_key.id
}
output "cd_user_access_key_secret" {
  description = "Access key secret for CD user"
  value       = aws_iam_access_key.cd_user_access_key.secret
  sensitive   = true
}


#########################################################
# Outputs for ECR repositories for app and proxy images #
#########################################################

output "ecr_repo_app" {
  description = "ECR repository URL for app image"
  value       = aws_ecr_repository.recipe_app_api_app.repository_url
}
output "ecr_repo_proxy" {
  description = "ECR repository URL for the proxy image"
  value       = aws_ecr_repository.recipe_app_api_app.repository_url
}