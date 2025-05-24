# ECR repos in prod account for storing Docker images #
resource "aws_ecr_repository" "recipe_app_api_app" {
  name                 = "recipe-app-api-app"
  provider             = aws.prod
  image_tag_mutability = "MUTABLE"
  force_delete         = true #Set for demo purposes only
  image_scanning_configuration {
    scan_on_push = false #Set true for real deployments.
  }
}
resource "aws_ecr_lifecycle_policy" "recipe_app_api_app" {
  provider   = aws.prod
  repository = aws_ecr_repository.recipe_app_api_app.name
  policy     = data.aws_ecr_lifecycle_policy_document.retain_last_10_tagged.json
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
resource "aws_ecr_lifecycle_policy" "recipe_app_api_proxy" {
  provider   = aws.prod
  repository = aws_ecr_repository.recipe_app_api_proxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.retain_last_10_tagged.json
}
data "aws_ecr_lifecycle_policy_document" "retain_last_10_tagged" {
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "imageCountMoreThan"
      count_number     = 10
    }
    action {
      type = "expire"
    }
  }
}
