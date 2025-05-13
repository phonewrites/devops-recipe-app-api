#################################################
# MODIFICATIONS TO AVOID LONG-LIVED ACCESS KEYS #
#################################################

data "aws_s3_bucket" "tf_state_bucket" {
  bucket = var.tf_state_bucket
}
data "aws_dynamodb_table" "tf_state_lock_table" {
  name = var.tf_state_lock_table
}

# OIDC provider to authenticate & authorize GH Actions workflows to access AWS resources
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# Initial role assumed by GitHub Actions workflows during deployments
resource "aws_iam_role" "oidc_github_actions_role" {
  name               = "oidc-gh-actions-role"
  description        = "Initial role assumed by GitHub Actions workflows during deployments."
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  depends_on         = [aws_iam_openid_connect_provider.github_actions]
}
data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:phonewrites/devops-recipe-app-api:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

##1. Policy to assume the Terraform Backend Access role in mgmt account
resource "aws_iam_policy" "oidc_assume_tf_backend_access_role_policy" {
  name   = "oidc-assume-tf-backend-access-role-policy"
  policy = data.aws_iam_policy_document.assume_tf_backend_access_role_policy.json
}
resource "aws_iam_role_policy_attachment" "oidc_assume_tf_backend_access_role_policy" {
  role       = aws_iam_role.oidc_github_actions_role.name
  policy_arn = aws_iam_policy.oidc_assume_tf_backend_access_role_policy.arn
}

##2. Policy to assume the CICD role in prod account
resource "aws_iam_policy" "oidc_assume_cicd_gh_actions_role_policy" {
  name   = "oidc-assume-cicd-gh-actions-role-policy"
  policy = data.aws_iam_policy_document.oidc_assume_cicd_gh_actions_role_policy.json
}
data "aws_iam_policy_document" "oidc_assume_cicd_gh_actions_role_policy" {
  statement {
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    effect    = "Allow"
    resources = [aws_iam_role.cicd_gh_actions_role.arn]
  }
}
resource "aws_iam_role_policy_attachment" "oidc_assume_cicd_gh_actions_role_policy" {
  role       = aws_iam_role.oidc_github_actions_role.name
  policy_arn = aws_iam_policy.oidc_assume_cicd_gh_actions_role_policy.arn
}

# ##3. Policy for Teraform backend to S3 and DynamoDB access
# resource "aws_iam_policy" "oidc_tf_backend_policy" {
#   name        = "${aws_iam_role.oidc_github_actions_role.name}-tf-backend-policy"
#   description = "Allow access to S3 & DynamoDB for TF backend resources"
#   policy      = data.aws_iam_policy_document.tf_backend_access_policy.json
# }
# resource "aws_iam_role_policy_attachment" "oidc_tf_backend_policy" {
#   role       = aws_iam_role.oidc_github_actions_role.name
#   policy_arn = aws_iam_policy.oidc_tf_backend_policy.arn
# }


# Teraform state backend bucket policy for prod account's CICD role access
resource "aws_s3_bucket_policy" "tf_state_bucket_policy" {
  bucket = data.aws_s3_bucket.tf_state_bucket.id
  policy = data.aws_iam_policy_document.tf_state_bucket_policy.json
}
data "aws_iam_policy_document" "tf_state_bucket_policy" {
  statement {
    sid    = "AllowProdCICDRoleAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        # aws_iam_role.oidc_github_actions_role.arn,
        # aws_iam_role.cicd_gh_actions_role.arn,
        aws_iam_role.tf_backend_access_role.arn,
      ]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      data.aws_s3_bucket.tf_state_bucket.arn,
      "${data.aws_s3_bucket.tf_state_bucket.arn}/*",
    ]
  }
}

# Teraform state lock table resource policy for prod account's CICD role access
resource "aws_dynamodb_resource_policy" "tf_state_lock_table_policy" {
  resource_arn = data.aws_dynamodb_table.tf_state_lock_table.arn
  policy       = data.aws_iam_policy_document.tf_state_lock_table_policy.json
}
data "aws_iam_policy_document" "tf_state_lock_table_policy" {
  statement {
    sid    = "AllowProdCICDRoleAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        # aws_iam_role.oidc_github_actions_role.arn,
        # aws_iam_role.cicd_gh_actions_role.arn,
        aws_iam_role.tf_backend_access_role.arn,
      ]
    }
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [data.aws_dynamodb_table.tf_state_lock_table.arn]

  }
}



