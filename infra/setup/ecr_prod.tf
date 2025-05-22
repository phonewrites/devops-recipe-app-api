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
# resource "aws_ecr_lifecycle_policy" "recipe_app_api_app" {
#   repository = aws_ecr_repository.recipe_app_api_app.name
#   policy = data.aws_ecr_lifecycle_policy_document.recipe_app_api_app.json
# }
# data "aws_ecr_lifecycle_policy_document" "recipe_app_api_app" {
#   rule {
#     priority    = 1
#     description = "Keep last 10 images"
#     selection {
#       tag_status      = "tagged"
#       tag_prefix_list = ["prod"]
#       count_type      = "imageCountMoreThan"
#       count_number    = 100
#     }
#   }
# }


#   lifecycle_policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         selection = {
#           tagStatus = "any"
#           countType = "imageCountMoreThan"
#           countNumber = 10
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })

#   policy = <<EOF
# {
#     "rules": [
#         {
#             "rulePriority": 1,
#             "description": "Keep last 10 images",
#             "selection": {
#                 "tagStatus": "any",
#                 "tagPrefixList": ["v"],
#                 "countType": "imageCountMoreThan",
#                 "countNumber": 30
#             },
#             "action": {
#                 "type": "expire"
#             }
#         }
#     ]
# }
# EOF



resource "aws_ecr_repository" "recipe_app_api_proxy" {
  name                 = "recipe-app-api-proxy"
  provider             = aws.prod
  image_tag_mutability = "MUTABLE"
  force_delete         = true #Set for demo purposes only
  image_scanning_configuration {
    scan_on_push = false #Set true for real deployments.
  }
}
