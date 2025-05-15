resource "aws_s3_bucket" "test" {
  bucket = "my-tf-test-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.id}"
force_destroy = true
}