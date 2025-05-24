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


##1. IAM policy to assume the Terraform Backend Access role in mgmt account
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

##2. IAM policy for deployments by GitHub Actions
# resource "aws_iam_policy" "cicd_gh_actions_policy" {
#   provider    = aws.prod
#   name        = "${aws_iam_role.cicd_gh_actions_role.name}-policy"
#   description = "Allow managing resources in prod account for deployments"
#   policy      = data.aws_iam_policy_document.cicd_gh_actions_policy.json
# }
###TO DO: Separate into separate IAM policies
# data "aws_iam_policy_document" "cicd_gh_actions_policy" {
# statement {
#   sid       = "GetECRAuthToken"
#   effect    = "Allow"
#   actions   = ["ecr:GetAuthorizationToken"]
#   resources = ["*"]
# }
# statement {
#   sid    = "ECRRepositoryPushPull"
#   effect = "Allow"
#   actions = [
#     "ecr:CompleteLayerUpload",
#     "ecr:UploadLayerPart",
#     "ecr:InitiateLayerUpload",
#     "ecr:BatchCheckLayerAvailability",
#     "ecr:PutImage",
#     "ecr:BatchGetImage",
#     "ecr:GetDownloadUrlForLayer",
#   ]
#   resources = [
#     aws_ecr_repository.recipe_app_api_app.arn,
#     aws_ecr_repository.recipe_app_api_proxy.arn,
#   ]
# }
# statement {
#   sid    = "ManageVPC"
#   effect = "Allow"
#   actions = [
#     "ec2:DescribeVpcs",
#     "ec2:CreateTags",
#     "ec2:CreateVpc",
#     "ec2:DeleteVpc",
#     "ec2:DescribeSecurityGroups",
#     "ec2:DescribeSecurityGroupRules",
#     "ec2:DeleteSubnet",
#     "ec2:DeleteSecurityGroup",
#     "ec2:DescribeNetworkInterfaces",
#     "ec2:DetachInternetGateway",
#     "ec2:DescribeInternetGateways",
#     "ec2:DeleteInternetGateway",
#     "ec2:DetachNetworkInterface",
#     "ec2:DescribeVpcEndpoints",
#     "ec2:DescribeRouteTables",
#     "ec2:DescribeAvailabilityZones", #for data.aws_availability_zones
#     "ec2:DeleteRouteTable",
#     "ec2:DeleteVpcEndpoints",
#     "ec2:DisassociateRouteTable",
#     "ec2:DeleteRoute",
#     "ec2:DescribePrefixLists",
#     "ec2:DescribeSubnets",
#     "ec2:DescribeVpcAttribute",
#     "ec2:DescribeNetworkAcls",
#     "ec2:AssociateRouteTable",
#     "ec2:AuthorizeSecurityGroupIngress",
#     "ec2:RevokeSecurityGroupEgress",
#     "ec2:CreateSecurityGroup",
#     "ec2:AuthorizeSecurityGroupEgress",
#     "ec2:CreateVpcEndpoint",
#     "ec2:ModifyVpcEndpoint",
#     "ec2:ModifySubnetAttribute",
#     "ec2:CreateSubnet",
#     "ec2:CreateRoute",
#     "ec2:CreateRouteTable",
#     "ec2:CreateInternetGateway",
#     "ec2:AttachInternetGateway",
#     "ec2:ModifyVpcAttribute",
#     "ec2:RevokeSecurityGroupIngress",
#   ]
#   resources = ["*"]
# }
# statement {
#   sid    = "ManageRDS"
#   effect = "Allow"
#   actions = [
#     "rds:DescribeDBSubnetGroups",
#     "rds:DescribeDBInstances",
#     "rds:CreateDBSubnetGroup",
#     "rds:DeleteDBSubnetGroup",
#     "rds:CreateDBInstance",
#     "rds:DeleteDBInstance",
#     "rds:ListTagsForResource",
#     "rds:ModifyDBInstance",
#     "rds:AddTagsToResource"
#   ]
#   resources = ["*"]
# }
# statement {
#   sid    = "ManageECS"
#   effect = "Allow"
#   actions = [
#     "ecs:DescribeClusters",
#     "ecs:DeregisterTaskDefinition",
#     "ecs:DeleteCluster",
#     "ecs:DescribeServices",
#     "ecs:UpdateService",
#     "ecs:DeleteService",
#     "ecs:DescribeTaskDefinition",
#     "ecs:CreateService",
#     "ecs:RegisterTaskDefinition",
#     "ecs:CreateCluster",
#     "ecs:UpdateCluster",
#     "ecs:TagResource",
#   ]
#   resources = ["*"]
# }
# statement {
#   sid    = "ManageALB"
#   effect = "Allow"
#   actions = [
#     "elasticloadbalancing:DeleteLoadBalancer",
#     "elasticloadbalancing:DeleteTargetGroup",
#     "elasticloadbalancing:DeleteListener",
#     "elasticloadbalancing:DescribeListeners",
#     "elasticloadbalancing:DescribeLoadBalancerAttributes",
#     "elasticloadbalancing:DescribeTargetGroups",
#     "elasticloadbalancing:DescribeTargetGroupAttributes",
#     "elasticloadbalancing:DescribeLoadBalancers",
#     "elasticloadbalancing:CreateListener",
#     "elasticloadbalancing:SetSecurityGroups",
#     "elasticloadbalancing:ModifyLoadBalancerAttributes",
#     "elasticloadbalancing:CreateLoadBalancer",
#     "elasticloadbalancing:ModifyTargetGroupAttributes",
#     "elasticloadbalancing:CreateTargetGroup",
#     "elasticloadbalancing:AddTags",
#     "elasticloadbalancing:DescribeTags",
#     "elasticloadbalancing:ModifyListener",
#     "elasticloadbalancing:ModifyListenerAttributes",
#     "elasticloadbalancing:DescribeListenerAttributes",
#   ]
#   resources = ["*"]
# }
# statement {
#   sid    = "ManageCWLogs"
#   effect = "Allow"
#   actions = [
#     "logs:DeleteLogGroup",
#     "logs:DescribeLogGroups",
#     "logs:CreateLogGroup",
#     "logs:TagResource",
#     "logs:ListTagsLogGroup",
#     "logs:ListTagsForResource",
#   ]
#   resources = ["*"]
# }
# statement { # Try sans managed AmazonElasticFileSystemFullAccess policy
#   sid    = "ManageEFS"
#   effect = "Allow"
#   actions = [
#     "ec2:DescribeNetworkInterfaceAttribute",
#     "elasticfilesystem:CreateTags",
#     "elasticfilesystem:CreateReplicationConfiguration",
#     "elasticfilesystem:DeleteTags",
#     "elasticfilesystem:DeleteFileSystemPolicy",
#     "elasticfilesystem:DeleteReplicationConfiguration",
#     "elasticfilesystem:DescribeAccountPreferences",
#     "elasticfilesystem:DescribeBackupPolicy",
#     "elasticfilesystem:DescribeFileSystemPolicy",
#     "elasticfilesystem:DescribeTags",
#     "elasticfilesystem:DescribeReplicationConfigurations",
#     "elasticfilesystem:ModifyMountTargetSecurityGroups",
#     "elasticfilesystem:PutAccountPreferences",
#     "elasticfilesystem:PutBackupPolicy",
#     "elasticfilesystem:PutLifecycleConfiguration",
#     "elasticfilesystem:PutFileSystemPolicy",
#     "elasticfilesystem:UpdateFileSystem",
#     "elasticfilesystem:UpdateFileSystemProtection",
#     "elasticfilesystem:UntagResource",
#     "elasticfilesystem:ListTagsForResource",
#     "elasticfilesystem:Backup",
#     "elasticfilesystem:Restore",
#     "elasticfilesystem:ReplicationRead",
#     "elasticfilesystem:ReplicationWrite",
#   ]
#   resources = ["*"]
# }
# statement {
#   sid    = "ManageCustomSubdomain"
#   effect = "Allow"
#   actions = [
#     "route53:ListHostedZones",
#     "route53:ListHostedZones",
#     "route53:ChangeTagsForResource",
#     "route53:GetHostedZone",
#     "route53:ListTagsForResource",
#     "route53:ChangeResourceRecordSets",
#     "route53:GetChange",
#     "route53:ListResourceRecordSets",
#     "acm:RequestCertificate",
#     "acm:AddTagsToCertificate",
#     "acm:DescribeCertificate",
#     "acm:ListTagsForCertificate",
#     "acm:DeleteCertificate",
#     "acm:CreateCertificate"
#   ]
#   resources = ["*"]
# }
# statement {
#   sid    = "ManageIAM"
#   effect = "Allow"
#   actions = [
#     "iam:ListInstanceProfilesForRole",
#     "iam:ListAttachedRolePolicies",
#     "iam:DeleteRole",
#     "iam:ListPolicyVersions",
#     "iam:DeletePolicy",
#     "iam:DetachRolePolicy",
#     "iam:ListRolePolicies",
#     "iam:GetRole",
#     "iam:GetPolicyVersion",
#     "iam:GetPolicy",
#     "iam:CreateRole",
#     "iam:CreatePolicy",
#     "iam:AttachRolePolicy",
#     "iam:TagRole",
#     "iam:TagPolicy",
#     "iam:PassRole"
#   ]
#   resources = ["*"]
# }
# statement {
#   #Create service-linked roles needed for first deployments
#   sid    = "CreateServiceLinkedRoles"
#   effect = "Allow"
#   actions = [
#     "iam:CreateServiceLinkedRole",
#   ]
#   resources = [
#     "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
#     "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
#     "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
#     "arn:aws:iam::*:role/aws-service-role/elasticfilesystem.amazonaws.com/AWSServiceRoleForAmazonElasticFileSystem",
#   ]
#   condition {
#     test     = "StringEquals"
#     variable = "iam:AWSServiceName"
#     values = [
#       "rds.amazonaws.com",
#       "ecs.amazonaws.com",
#       "elasticloadbalancing.amazonaws.com",
#       "elasticfilesystem.amazonaws.com",
#     ]
#   }
# }
# statement {
#   #Delete service-linked roles during Destroy workflows
#   sid    = "DeleteServiceLinkedRoles"
#   effect = "Allow"
#   actions = [
#     "iam:DeleteServiceLinkedRole",
#     "iam:GetServiceLinkedRoleDeletionStatus"
#   ]
#   resources = [
#     "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
#     "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
#     "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
#     "arn:aws:iam::*:role/aws-service-role/elasticfilesystem.amazonaws.com/AWSServiceRoleForAmazonElasticFileSystem",
#   ]
# }
# statement {
#   sid    = "S3FullAccess"
#   effect = "Allow"
#   actions = [
#     "s3:*",
#     "s3-object-lambda:*"
#   ]
#   resources = ["*"]
# }
# }
# resource "aws_iam_role_policy_attachment" "cicd_gh_actions_policy" {
#   provider   = aws.prod
#   role       = aws_iam_role.cicd_gh_actions_role.name
#   policy_arn = aws_iam_policy.cicd_gh_actions_policy.arn
# }
# resource "aws_iam_role_policy_attachment" "amazon_managed_efs_full_access_policy" {
#   provider   = aws.prod
#   role       = aws_iam_role.cicd_gh_actions_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
# }



####### TO DO: Separate into separate IAM policies
##2. IAM policies for deployments by GitHub Actions
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
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyListenerAttributes",
      "elasticloadbalancing:DescribeListenerAttributes",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_alb_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_alb_policy.arn
}

resource "aws_iam_policy" "cicd_gha_iam_policy" {
  provider    = aws.prod
  name        = "cicd-gha-iam-policy"
  description = "Allow managing IAM resources in prod account for deployments"
  policy      = data.aws_iam_policy_document.cicd_gha_iam_policy.json
}
data "aws_iam_policy_document" "cicd_gha_iam_policy" {
  statement {
    sid    = "ManageBasicIAM"
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
      "iam:PassRole",
      # Service-linked roles permissions for all possible roles
      # "iam:CreateServiceLinkedRole",
      # "iam:DeleteServiceLinkedRole",
      # "iam:GetServiceLinkedRoleDeletionStatus",
    ]
    resources = ["*"]
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
  statement {
    #Delete service-linked roles selectively during Destroy runs
    sid    = "DeleteServiceLinkedRoles"
    effect = "Allow"
    actions = [
      "iam:DeleteServiceLinkedRole",
      "iam:GetServiceLinkedRoleDeletionStatus"
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
      "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
      "arn:aws:iam::*:role/aws-service-role/elasticfilesystem.amazonaws.com/AWSServiceRoleForAmazonElasticFileSystem",
    ]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_iam_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_iam_policy.arn
}

resource "aws_iam_policy" "cicd_gha_cw_policy" {
  provider    = aws.prod
  name        = "cicd-gha-cw-policy"
  description = "Allow managing CloudWatch resources in prod account for logging"
  policy      = data.aws_iam_policy_document.cicd_gha_cw_policy.json
}
data "aws_iam_policy_document" "cicd_gha_cw_policy" {
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
}
resource "aws_iam_role_policy_attachment" "cicd_gha_cw_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_cw_policy.arn
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
      "ec2:DescribeNetworkInterfaceAttribute",
      "elasticfilesystem:CreateTags",
      "elasticfilesystem:CreateReplicationConfiguration",
      "elasticfilesystem:DeleteTags",
      "elasticfilesystem:DeleteFileSystemPolicy",
      "elasticfilesystem:DeleteReplicationConfiguration",
      "elasticfilesystem:DescribeAccountPreferences",
      "elasticfilesystem:DescribeBackupPolicy",
      "elasticfilesystem:DescribeFileSystemPolicy",
      "elasticfilesystem:DescribeTags",
      "elasticfilesystem:DescribeReplicationConfigurations",
      "elasticfilesystem:ModifyMountTargetSecurityGroups",
      "elasticfilesystem:PutAccountPreferences",
      "elasticfilesystem:PutBackupPolicy",
      "elasticfilesystem:PutLifecycleConfiguration",
      "elasticfilesystem:PutFileSystemPolicy",
      "elasticfilesystem:UpdateFileSystem",
      "elasticfilesystem:UpdateFileSystemProtection",
      "elasticfilesystem:UntagResource",
      "elasticfilesystem:ListTagsForResource",
      "elasticfilesystem:Backup",
      "elasticfilesystem:Restore",
      "elasticfilesystem:ReplicationRead",
      "elasticfilesystem:ReplicationWrite",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "cicd_gha_efs_policy" {
  provider   = aws.prod
  role       = aws_iam_role.cicd_gh_actions_role.name
  policy_arn = aws_iam_policy.cicd_gha_efs_policy.arn
}