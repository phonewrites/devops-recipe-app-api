#################################################
# MODIFICATIONS TO AVOID LONG-LIVED ACCESS KEYS #
#################################################


# OIDC provider to authenticate & authorize GH Actions workflows to access AWS resources
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# Initial role assumed by GitHub Actions workflows during deployments
resource "aws_iam_role" "oidc_github_actions_role" {
  name               = "oidc-gh-actions-role"
  description        = "Initial role assumed by GitHub Actions workflows during deployments."
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  depends_on         = [aws_iam_openid_connect_provider.github_actions]
}

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:phonewrites/devops-recipe-app-api:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_policy" "assume_cicd_gh_actions_role_policy" {
  name   = "assume-cicd-gh-actions-role-policy"
  policy = data.aws_iam_policy_document.assume_cicd_gh_actions_role_policy.json
}
data "aws_iam_policy_document" "assume_cicd_gh_actions_role_policy" {
  statement {
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    effect    = "Allow"
    resources = [aws_iam_role.cicd_gh_actions_role.arn]
  }
}
resource "aws_iam_role_policy_attachment" "assume_cicd_gh_actions_role_policy" {
  role       = aws_iam_role.oidc_github_actions_role.name
  policy_arn = aws_iam_policy.assume_cicd_gh_actions_role_policy.arn
}


