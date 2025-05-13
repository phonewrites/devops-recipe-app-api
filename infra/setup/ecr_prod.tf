######################################################
# Create ECR repos in prod for storing Docker images #
######################################################

resource "aws_ecr_repository" "recipe_app_api_app" {
  name                 = "recipe-app-api-app"
  provider             = aws.prod
  image_tag_mutability = "MUTABLE"
  force_delete         = true #Set for demo purposes only
  image_scanning_configuration {
    scan_on_push = false #Set true for real deployments.
  }
}
resource "aws_ecr_repository" "recipe_app_api_proxy" {
  name                 = "recipe-app-api-proxy"
  provider             = aws.prod
  image_tag_mutability = "MUTABLE"
  force_delete         = true #Set for demo purposes only
  image_scanning_configuration {
    scan_on_push = false #Set true for real deployments.
  }
}
