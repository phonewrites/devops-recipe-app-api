
# to test/fix s3 still creating loop 

resource "aws_s3_bucket" "test_s3_creating_loop" {
  bucket = "another-test-${data.aws_region.current.region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}