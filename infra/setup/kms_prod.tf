# CMK in prod account for SSM SecureStrings today + other secret crypto later.

data "aws_iam_policy_document" "kms_secrets" {
  statement {
    sid    = "EnableAccountRootKeyPolicy"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.prod.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "kms_secrets" {
  provider                = aws.prod
  description             = "Encrypts secret material for ${var.project} (SSM and other consumers)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_secrets.json
  tags = {
    Name    = "/${var.project}/secrets"
    Project = var.project
  }
}

resource "aws_kms_alias" "alias_secrets" {
  provider      = aws.prod
  name          = "alias/${var.project}/secrets"
  target_key_id = aws_kms_key.kms_secrets.key_id
}
