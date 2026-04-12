data "aws_region" "prod" {
  provider = aws.prod
}
data "aws_caller_identity" "prod" {
  provider = aws.prod
}

locals {
  cicd_prod_region     = data.aws_region.prod.id
  cicd_prod_account_id = data.aws_caller_identity.prod.account_id
  # Deploy workspaces this repo uses (log group name = "<workspace>/<project>")
  cicd_prod_cw_log_arns = [
    "arn:aws:logs:${local.cicd_prod_region}:${local.cicd_prod_account_id}:log-group:staging/${var.project}",
    "arn:aws:logs:${local.cicd_prod_region}:${local.cicd_prod_account_id}:log-group:staging/${var.project}:log-stream:*",
    "arn:aws:logs:${local.cicd_prod_region}:${local.cicd_prod_account_id}:log-group:prod/${var.project}",
    "arn:aws:logs:${local.cicd_prod_region}:${local.cicd_prod_account_id}:log-group:prod/${var.project}:log-stream:*",
  ]
  # CreateDBInstance also needs default og/pg ARNs in addition to db + subgrp for this app.
  cicd_prod_rds_arns = [
    "arn:aws:rds:${local.cicd_prod_region}:${local.cicd_prod_account_id}:db:recipe-api-*",
    "arn:aws:rds:${local.cicd_prod_region}:${local.cicd_prod_account_id}:subgrp:recipe-api-*",
    "arn:aws:rds:${local.cicd_prod_region}:${local.cicd_prod_account_id}:og:*",
    "arn:aws:rds:${local.cicd_prod_region}:${local.cicd_prod_account_id}:pg:*",
  ]
  cicd_prod_elb_arns = [
    "arn:aws:elasticloadbalancing:${local.cicd_prod_region}:${local.cicd_prod_account_id}:loadbalancer/app/recipe-api-*/*",
    "arn:aws:elasticloadbalancing:${local.cicd_prod_region}:${local.cicd_prod_account_id}:targetgroup/recipe-api-*/*",
    "arn:aws:elasticloadbalancing:${local.cicd_prod_region}:${local.cicd_prod_account_id}:listener/app/recipe-api-*/*/*",
    "arn:aws:elasticloadbalancing:${local.cicd_prod_region}:${local.cicd_prod_account_id}:listener-rule/app/recipe-api-*/*/*/*",
  ]
  cicd_prod_iam_app_arns = [
    "arn:aws:iam::${local.cicd_prod_account_id}:role/recipe-api-*",
    "arn:aws:iam::${local.cicd_prod_account_id}:policy/recipe-api-*",
  ]
}

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


##1 IAM policy to assume the Terraform Backend Access role in mgmt account
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

##2-11 IAM policies for deployments by GitHub Actions
resource "aws_iam_policy" "cicd_gha_ecr_policy" {
  provider    = aws.prod
  name        = "cicd-gha-ecr-policy"
  description = "Allow managing ECR resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_ecr_policy.json
}
data "aws_iam_policy_document" "cicd_gha_ecr_policy" {
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
}
resource "aws_iam_role_policy_attachment" "cicd_gha_ecr_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_ecr_policy.arn
}

resource "aws_iam_policy" "cicd_gha_vpc_policy" {
  provider    = aws.prod
  name        = "cicd-gha-vpc-policy"
  description = "Allow managing Network resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_vpc_policy.json
}
data "aws_iam_policy_document" "cicd_gha_vpc_policy" {
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
}
resource "aws_iam_role_policy_attachment" "cicd_gha_vpc_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_vpc_policy.arn
}

resource "aws_iam_policy" "cicd_gha_rds_policy" {
  provider    = aws.prod
  name        = "cicd-gha-rds-policy"
  description = "Allow managing RDS resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_rds_policy.json
}
data "aws_iam_policy_document" "cicd_gha_rds_policy" {
  statement {
    sid    = "DescribeRDS"
    effect = "Allow"
    actions = [
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBInstances",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ScopedMutateRDS"
    effect = "Allow"
    actions = [
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ListTagsForResource",
      "rds:ModifyDBInstance",
      "rds:AddTagsToResource",
    ]
    resources = local.cicd_prod_rds_arns
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_rds_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_rds_policy.arn
}

resource "aws_iam_policy" "cicd_gha_ecs_policy" {
  provider    = aws.prod
  name        = "cicd-gha-ecs-policy"
  description = "Allow managing ECS resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_ecs_policy.json
}

data "aws_iam_policy_document" "cicd_gha_ecs_policy" {
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
      #Fix failing gh actions due to wait_for_steady_state = true
      "ecs:ListServiceDeployments",
      "ecs:DescribeServiceDeployments",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_ecs_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_ecs_policy.arn
}

resource "aws_iam_policy" "cicd_gha_alb_policy" {
  provider    = aws.prod
  name        = "cicd-gha-alb-policy"
  description = "Allow managing ALB resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_alb_policy.json
}
data "aws_iam_policy_document" "cicd_gha_alb_policy" {
  statement {
    sid    = "DescribeALB"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeListenerAttributes",
      "ec2:DescribeAccountAttributes",
      "ec2:GetSecurityGroupsForVpc",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "CreateALB"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateListener",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ScopedManageALB"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyListenerAttributes",
    ]
    resources = local.cicd_prod_elb_arns
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_alb_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_alb_policy.arn
}

resource "aws_iam_policy" "cicd_gha_cw_policy" {
  provider    = aws.prod
  name        = "cicd-gha-cw-policy"
  description = "Allow managing CloudWatch resources in prod account for logging"
  policy      = data.aws_iam_policy_document.cicd_gha_cw_policy.json
}
data "aws_iam_policy_document" "cicd_gha_cw_policy" {
  statement {
    sid    = "DescribeCWLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ScopedManageCWLogs"
    effect = "Allow"
    actions = [
      "logs:DeleteLogGroup",
      "logs:CreateLogGroup",
      "logs:TagResource",
      "logs:ListTagsLogGroup",
      "logs:ListTagsForResource",
    ]
    resources = local.cicd_prod_cw_log_arns
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_cw_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_cw_policy.arn
}

resource "aws_iam_policy" "cicd_gha_efs_policy" {
  provider    = aws.prod
  name        = "cicd-gha-efs-policy"
  description = "Allow managing EFS resources in prod account for persistent data"
  policy      = data.aws_iam_policy_document.cicd_gha_efs_policy.json
}
data "aws_iam_policy_document" "cicd_gha_efs_policy" {
  statement { # Try sans managed AmazonElasticFileSystemFullAccess policy
    sid    = "ManageEFS"
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateFileSystem",
      "elasticfilesystem:CreateMountTarget",
      "elasticfilesystem:CreateTags",
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:CreateReplicationConfiguration",
      "elasticfilesystem:DeleteFileSystem",
      "elasticfilesystem:DeleteMountTarget",
      "elasticfilesystem:DeleteTags",
      "elasticfilesystem:DeleteAccessPoint",
      "elasticfilesystem:DeleteFileSystemPolicy",
      "elasticfilesystem:DeleteReplicationConfiguration",
      "elasticfilesystem:DescribeAccountPreferences",
      "elasticfilesystem:DescribeBackupPolicy",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeFileSystemPolicy",
      "elasticfilesystem:DescribeLifecycleConfiguration",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeMountTargetSecurityGroups",
      "elasticfilesystem:DescribeTags",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeReplicationConfigurations",
      "elasticfilesystem:ModifyMountTargetSecurityGroups",
      "elasticfilesystem:PutAccountPreferences",
      "elasticfilesystem:PutBackupPolicy",
      "elasticfilesystem:PutLifecycleConfiguration",
      "elasticfilesystem:PutFileSystemPolicy",
      "elasticfilesystem:UpdateFileSystem",
      "elasticfilesystem:UpdateFileSystemProtection",
      "elasticfilesystem:TagResource",
      "elasticfilesystem:UntagResource",
      "elasticfilesystem:ListTagsForResource",
      "elasticfilesystem:Backup",
      "elasticfilesystem:Restore",
      "elasticfilesystem:ReplicationRead",
      "elasticfilesystem:ReplicationWrite",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_efs_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_efs_policy.arn
}

resource "aws_iam_policy" "cicd_gha_iam_policy" {
  provider    = aws.prod
  name        = "cicd-gha-iam-policy"
  description = "Allow managing IAM resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_iam_policy.json
}
data "aws_iam_policy_document" "cicd_gha_iam_policy" {
  # CreateRole / CreatePolicy do not support resource-level permissions on the new name.
  statement {
    sid    = "CreateIAMRoleAndPolicy"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:CreatePolicy",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ScopedManageIAM"
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
      "iam:AttachRolePolicy",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:PassRole",
    ]
    resources = local.cicd_prod_iam_app_arns
  }
  statement {
    #Create service-linked roles selectively for first deployments
    sid    = "CreateServiceLinkedRoles"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
      "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
      "arn:aws:iam::*:role/aws-service-role/elasticfilesystem.amazonaws.com/AWSServiceRoleForAmazonElasticFileSystem",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "rds.amazonaws.com",
        "ecs.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "elasticfilesystem.amazonaws.com",
      ]
    }
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_iam_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_iam_policy.arn
}

resource "aws_iam_policy" "cicd_gha_dns_policy" {
  provider    = aws.prod
  name        = "cicd-gha-dns-policy"
  description = "Allow managing resources needed to manage a custom domain in prod account"
  policy      = data.aws_iam_policy_document.cicd_gha_dns_policy.json
}
data "aws_iam_policy_document" "cicd_gha_dns_policy" {
  statement {
    sid    = "ManageCustomSubdomain"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZones",
      "route53:ChangeTagsForResource",
      "route53:GetHostedZone",
      "route53:ListTagsForResource",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "route53:ListResourceRecordSets",
      "acm:RequestCertificate",
      "acm:AddTagsToCertificate",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
      "acm:DeleteCertificate",
      "acm:CreateCertificate"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_dns_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_dns_policy.arn
}

resource "aws_iam_policy" "cicd_gha_ssm_params_policy" {
  provider    = aws.prod
  name        = "cicd-gha-ssm-params-policy"
  description = "Allow Terraform in CI to manage SecureString SSM parameters used by ECS"
  policy      = data.aws_iam_policy_document.cicd_gha_ssm_params_policy.json
}
data "aws_iam_policy_document" "cicd_gha_ssm_params_policy" {
  # DescribeParameters is evaluated against arn:aws:ssm:region:account:* and cannot be
  # scoped to parameter path ARNs (unlike PutParameter / GetParameter).
  statement {
    sid    = "ManageParameters"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:AddTagsToResource",
      "ssm:RemoveTagsFromResource",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.cicd_prod_region}:${local.cicd_prod_account_id}:parameter/recipe-api-*"
    ]
  }
  statement {
    sid    = "UseCMK"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.kms_secrets.arn,
    ]
  }
  statement {
    sid       = "ListKMSAliases"
    effect    = "Allow"
    actions   = ["kms:ListAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "DescribeParameters"
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_ssm_params_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_ssm_params_policy.arn
}
