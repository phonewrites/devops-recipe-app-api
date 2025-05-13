data "aws_iam_policy_document" "tf_backend_access_policy" {
  statement {
    sid    = "BackendStateS3Access"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      data.aws_s3_bucket.tf_state_bucket.arn,
      "${data.aws_s3_bucket.tf_state_bucket.arn}/*",
    ]
  }
  statement {
    sid    = "BackendStateLockDynamoAccess"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [data.aws_dynamodb_table.tf_state_lock_table.arn]
  }
}

data "aws_iam_policy_document" "assume_tf_backend_access_role_policy" {
  statement {
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    effect    = "Allow"
    resources = [aws_iam_role.tf_backend_access_role.arn]
  }
}

# Role in MGMT account dedicated for Terraform backend access
resource "aws_iam_role" "tf_backend_access_role" {
  name               = "tf-backend-access-role"
  description        = "Role assumed by Terraform for backend operations in the mgmt account."
  assume_role_policy = data.aws_iam_policy_document.tf_backend_assume_role_policy.json
}

data "aws_iam_policy_document" "tf_backend_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.oidc_github_actions_role.arn,
        aws_iam_role.cicd_gh_actions_role.arn
      ]
    }
  }
}

# Policy for Teraform backend to S3 and DynamoDB access
resource "aws_iam_policy" "tf_backend_policy" {
  name        = "${aws_iam_role.tf_backend_access_role.name}-tf-backend-policy"
  description = "Allow access to S3 & DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend_access_policy.json
}
resource "aws_iam_role_policy_attachment" "tf_backend_policy" {
  role       = aws_iam_role.tf_backend_access_role.name
  policy_arn = aws_iam_policy.tf_backend_policy.arn
}