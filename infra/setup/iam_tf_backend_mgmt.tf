data "aws_s3_bucket" "tf_state_bucket" {
  bucket = var.tf_state_bucket
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
## Policy used by other roles to assume this role
data "aws_iam_policy_document" "assume_tf_backend_access_role_policy" {
  statement {
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    effect    = "Allow"
    resources = [aws_iam_role.tf_backend_access_role.arn]
  }
}


# Policy for Terraform backend S3 access
resource "aws_iam_policy" "tf_backend_access_policy" {
  name        = "${aws_iam_role.tf_backend_access_role.name}-policy"
  description = "Allow access to S3 for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend_access_policy.json
}
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
}
resource "aws_iam_role_policy_attachment" "tf_backend_policy" {
  role       = aws_iam_role.tf_backend_access_role.name
  policy_arn = aws_iam_policy.tf_backend_access_policy.arn
}

# TF state backend bucket policy for access by tf-backend-access-role
resource "aws_s3_bucket_policy" "tf_state_bucket_policy" {
  bucket = data.aws_s3_bucket.tf_state_bucket.id
  policy = data.aws_iam_policy_document.tf_state_bucket_policy.json
}
data "aws_iam_policy_document" "tf_state_bucket_policy" {
  statement {
    sid    = "TFBackendAccessRoleAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
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