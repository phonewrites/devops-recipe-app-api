# Main role in prod account for deployments
resource "aws_iam_role" "cicd_gh_actions_role" {
  provider           = aws.prod
  name               = "cicd-gh-actions-role"
  description        = "Main role used by GitHub Actions workflows for deployments"
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
    sid    = "ManageVPC"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DeleteSubnet",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:DeleteInternetGateway",
      "ec2:DetachNetworkInterface",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:DescribeAvailabilityZones", #for data.aws_availability_zones
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
      "ec2:ModifyVpcEndpoint",
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
    sid    = "ManageRDS"
    effect = "Allow"
    actions = [
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBInstances",
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ListTagsForResource",
      "rds:ModifyDBInstance",
      "rds:AddTagsToResource"
    ]
    resources = ["*"]
  }
  statement {
    #Create service-linked roles needed for first deployments
    sid    = "CreateServiceLinkedRoles"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForElasticLoadBalancing*", #try suffix
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "rds.amazonaws.com",
        "ecs.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
      ]
    }
  }
  statement {
    #Delete service-linked roles during terraform destroy
    sid    = "DeleteServiceLinkedRoles"
    effect = "Allow"
    actions = [
      "iam:DeleteServiceLinkedRole",
      "iam:GetServiceLinkedRoleDeletionStatus"
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForElasticLoadBalancing*", #try suffix
    ]
  }
  statement {
    sid    = "ManageECS"
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DeregisterTaskDefinition",
      "ecs:DeleteCluster",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:DescribeTaskDefinition",
      "ecs:CreateService",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateCluster",
      "ecs:UpdateCluster",
      "ecs:TagResource",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ManageALB"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:ModifyListener"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ManageIAM"
    effect = "Allow"
    actions = [
      "iam:ListInstanceProfilesForRole",
      "iam:ListAttachedRolePolicies",
      "iam:DeleteRole",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:AttachRolePolicy",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ManageCWLogs"
    effect = "Allow"
    actions = [
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:CreateLogGroup",
      "logs:TagResource",
      "logs:ListTagsLogGroup",
      "logs:ListTagsForResource",
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