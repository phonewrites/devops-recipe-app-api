resource "aws_iam_role" "cicd_gh_actions_role" {
  provider           = aws.prod
  name               = "cicd-gh-actions-role"
  assume_role_policy = data.aws_iam_policy_document.cicd_assume_role_policy.json
}

data "aws_iam_policy_document" "cicd_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.oidc_github_actions_role.arn]
    }
  }
}

# Policy for Teraform backend to S3 and DynamoDB access
resource "aws_iam_policy" "tf_backend_policy" {
  provider    = aws.prod
  name        = "${aws_iam_role.cicd_gh_actions_role.name}-tf-backend-policy"
  description = "Allow access to S3 & DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend_policy.json
}
data "aws_iam_policy_document" "tf_backend_policy" {
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
resource "aws_iam_role_policy_attachment" "tf_backend_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.tf_backend_policy.arn
}


# Policy for ECR access
resource "aws_iam_policy" "ecr_policy" {
  provider    = aws.prod
  name        = "${aws_iam_role.cicd_gh_actions_role.name}-ecr-policy"
  description = "Allow managing of ECR resources"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [
      aws_ecr_repository.recipe_app_api_app.arn,
      aws_ecr_repository.recipe_app_api_proxy.arn,
    ]
  }
}
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}



