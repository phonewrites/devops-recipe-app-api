data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "test_bucket" {
  bucket        = "tygvbkjbjb-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
}