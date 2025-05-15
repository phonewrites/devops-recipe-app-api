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


##1. Policy to assume the Terraform Backend Access role in mgmt account
resource "aws_iam_policy" "cicd_assume_tf_backend_access_role_policy" {
  provider = aws.prod
  name     = "cicd-assume-tf-backend-access-role-policy"
  policy   = data.aws_iam_policy_document.assume_tf_backend_access_role_policy.json
}
resource "aws_iam_role_policy_attachment" "cicd_assume_tf_backend_access_role_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_assume_tf_backend_access_role_policy.arn
}

##2. Policy for ECR access
resource "aws_iam_policy" "ecr_policy" {
  provider    = aws.prod
  name        = "${aws_iam_role.cicd_gh_actions_role.name}-ecr-policy"
  description = "Allow managing of ECR resources"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid       = "ECRAccess"
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
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      aws_ecr_repository.recipe_app_api_app.arn,
      aws_ecr_repository.recipe_app_api_proxy.arn,
    ]
  }
  # statement {
  #   sid    = "S3FullAccess"
  #   effect = "Allow"
  #   actions = [
  #     "s3:*",
  #     "s3-object-lambda:*"
  #   ]
  #   resources = ["*"]
  # }
}
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# ##3. Policy for Teraform backend to S3 and DynamoDB access
# resource "aws_iam_policy" "cicd_tf_backend_policy" {
#   provider    = aws.prod
#   name        = "${aws_iam_role.cicd_gh_actions_role.name}-tf-backend-policy"
#   description = "Allow access to S3 & DynamoDB for TF backend resources"
#   policy      = data.aws_iam_policy_document.tf_backend_access_policy.json
# }
# resource "aws_iam_role_policy_attachment" "cicd_tf_backend_policy" {
#   provider   = aws.prod
#   role       = aws_iam_role.cicd_gh_actions_role.name
#   policy_arn = aws_iam_policy.cicd_tf_backend_policy.arn
# }