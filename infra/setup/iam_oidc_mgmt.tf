# #######################################################
# # IAM resources needed for Continuous Deployment (CD) #
# #######################################################
# resource "aws_iam_user" "cd_user" {
#   name = "cd-user"
# }

# resource "aws_iam_access_key" "cd_user_access_key" {
#   user = aws_iam_user.cd_user.name
# }

# #########################################################
# # Policy for Teraform backend to S3 and DynamoDB access #
# #########################################################
# resource "aws_iam_policy" "tf_backend_policy" {
#   name        = "${aws_iam_user.cd_user.name}-tf-backend-policy"
#   description = "Allow user to use S3 and DynamoDB for TF backend resources"
#   policy      = data.aws_iam_policy_document.tf_backend_policy.json
# }

# data "aws_iam_policy_document" "tf_backend_policy" {
#   statement {
#     effect    = "Allow"
#     actions   = ["s3:ListBucket"]
#     resources = ["arn:aws:s3:::${var.tf_state_bucket}"]
#   }

#   statement {
#     effect  = "Allow"
#     actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
#     resources = [
#       "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy/*",
#       "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env/*"
#     ]
#   }
#   statement {
#     effect = "Allow"
#     actions = [
#       "dynamodb:DescribeTable",
#       "dynamodb:GetItem",
#       "dynamodb:PutItem",
#       "dynamodb:DeleteItem"
#     ]
#     resources = ["arn:aws:dynamodb:*:*:table/${var.tf_state_lock_table}"]
#   }
# }

# resource "aws_iam_user_policy_attachment" "tf_backend_policy_attachment" {
#   user       = aws_iam_user.cd_user.name
#   policy_arn = aws_iam_policy.tf_backend_policy.arn
# }

# #########################
# # Policy for ECR access #
# #########################
# resource "aws_iam_policy" "ecr_policy" {
#   name        = "${aws_iam_user.cd_user.name}-ecr-policy"
#   description = "Allow user to manage ECR resources"
#   policy      = data.aws_iam_policy_document.ecr_policy.json
# }

# data "aws_iam_policy_document" "ecr_policy" {
#   statement {
#     effect    = "Allow"
#     actions   = ["ecr:GetAuthorizationToken"]
#     resources = ["*"]
#   }
#   statement {
#     effect = "Allow"
#     actions = [
#       "ecr:CompleteLayerUpload",
#       "ecr:UploadLayerPart",
#       "ecr:InitiateLayerUpload",
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:PutImage"
#     ]
#     resources = [
#       aws_ecr_repository.recipe_app_api_app.arn,
#       aws_ecr_repository.recipe_app_api_proxy.arn,
#     ]
#   }
# }
# resource "aws_iam_user_policy_attachment" "ecr_policy_attachment" {
#   user       = aws_iam_user.cd_user.name
#   policy_arn = aws_iam_policy.ecr_policy.arn
# }









# #################################################
# #################################################
# #################################################
# # MODIFICATIONS TO AVOID LONG-LIVED ACCESS KEYS #
# #################################################


# # OIDC provider to authenticate & authorize GH Actions workflows to access AWS resources
# resource "aws_iam_openid_connect_provider" "github_actions" {
#   url = "https://token.actions.githubusercontent.com"
#   client_id_list = [
#     "sts.amazonaws.com",
#   ]
#   thumbprint_list = [
#     "6938fd4d98bab03faadb97b34396831e3780aea1",
#     "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
#   ]
# }

# # Initial role assumed by GitHub Actions workflows during deployments
# resource "aws_iam_role" "github_actions_oidc_role" {
#   name        = "github-actions-oidc-role"
#   description = "Initial role assumed by GitHub Actions workflows during deployments."
#   assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
#   depends_on         = [aws_iam_openid_connect_provider.github_actions]
# }

# data "aws_iam_policy_document" "oidc_assume_role_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
#     }
#     condition {
#       test     = "StringEquals"
#       values   = ["sts.amazonaws.com"]
#       variable = "token.actions.githubusercontent.com:aud"
#     }
#     condition {
#       test     = "StringLike"
#       values   = ["repo:phonewrites/devops-recipe-app-api:*"]
#       variable = "token.actions.githubusercontent.com:sub"
#     }
#   }
# }

# resource "aws_iam_policy" "assume_cicd_gh_actions_role_policy" {
#   name   = "assume-cicd-gh-actions-role-policy"
#   policy = data.aws_iam_policy_document.assume_cicd_gh_actions_role_policy.json
# }
# data "aws_iam_policy_document" "assume_cicd_gh_actions_role_policy" {
#   statement {
#     actions   = ["sts:AssumeRole", "sts:TagSession"]
#     effect    = "Allow"
#     resources = [aws_iam_role.cicd_gh_actions_role.arn]
#   }
# }
# resource "aws_iam_role_policy_attachment" "assume_cicd_gh_actions_role_policy" {
#   role      = [aws_iam_role.github_actions_oidc_role.name]
#   policy_arn = aws_iam_policy.assume_cicd_gh_actions_role_policy.arn
# }


