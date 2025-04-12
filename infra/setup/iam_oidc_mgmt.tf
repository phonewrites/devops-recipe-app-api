#######################################################
# IAM resources needed for Continuous Deployment (CD) #
#######################################################

resource "aws_iam_user" "cd" {
  name = "recipe-app-api-cd"
}

resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}

#########################################################
# Policy for Teraform backend to S3 and DynamoDB access #
#########################################################

data "aws_iam_policy_document" "tf_backend" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf_state_bucket}"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy/*",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.tf_state_lock_table}"]
  }
}

resource "aws_iam_policy" "tf_backend" {
  name        = "${aws_iam_user.cd.name}-tf-s3-dynamodb"
  description = "Allow user to use S3 and DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend.json
}

resource "aws_iam_user_policy_attachment" "tf_backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.tf_backend.arn
}


#########################################################
# Outputs for the CD user's access key and secret key   #
#########################################################
output "cd_user_access_key_id" {
  description = "Access key ID for CD user"
  value       = aws_iam_access_key.cd.id
}

output "cd_user_access_key_secret" {
  description = "Access key secret for CD user"
  value       = aws_iam_access_key.cd.secret
  sensitive   = true
}



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
#   # max_session_duration = 3600
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

