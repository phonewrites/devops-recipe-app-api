# resource "aws_iam_role" "cicd_gh_actions_role" {
#   provider             = aws.prod
#   name                 = "cicd-gh-actions-role"
#   assume_role_policy   = data.aws_iam_policy_document.cicd_assume_role_policy.json
# }

# data "aws_iam_policy_document" "cicd_assume_role_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = [aws_iam_role.github_actions_oidc_role.arn]
#     }
#   }
#   statement {
#     effect  = "Allow"
#     actions = ["sts:TagSession"]
#     principals {
#       type        = "AWS"
#       identifiers = [aws_iam_role.github_actions_oidc_role.arn]
#     }
#   }
# }

# resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
#   provider = aws.prod    
#   role       = aws_iam_role.cicd_gh_actions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
# }