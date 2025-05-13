data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "test_bucket" {
  bucket        = "tygvbkjbjb-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  force_destroy = true
}