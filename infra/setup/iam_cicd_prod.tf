# Main role in prod account for deployments
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

##2. Policy for deployments by GitHub Actions
resource "aws_iam_policy" "cicd_gh_actions_policy" {
  provider    = aws.prod
  name        = "${aws_iam_role.cicd_gh_actions_role.name}-policy"
  description = "Allow managing resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gh_actions_policy.json
}
data "aws_iam_policy_document" "cicd_gh_actions_policy" {
  statement {
    sid       = "GetECRAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "ECRRepositoryPushPull"
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
  statement {
    sid    = "VPCManagement"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:DescribeSecurityGroups",
      "ec2:DeleteSubnet",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:DeleteInternetGateway",
      "ec2:DetachNetworkInterface",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:DescribeAvailabilityZones",#for data.aws_availability_zones
      "ec2:DeleteRouteTable",
      "ec2:DeleteVpcEndpoints",
      "ec2:DisassociateRouteTable",
      "ec2:DeleteRoute",
      "ec2:DescribePrefixLists",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeNetworkAcls",
      "ec2:AssociateRouteTable",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:CreateVpcEndpoint",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateSubnet",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:ModifyVpcAttribute",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "S3FullAccess"
    effect = "Allow"
    actions = [
      "s3:*",
      "s3-object-lambda:*"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gh_actions_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gh_actions_policy.arn
}