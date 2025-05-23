# ECS Cluster for running the app on Fargate
resource "aws_ecs_cluster" "main" {
  name = local.prefix
}
resource "aws_ecs_service" "service" {
  name                   = "${local.prefix}-service"
  cluster                = aws_ecs_cluster.main.name
  task_definition        = aws_ecs_task_definition.taskdef.family
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true
  network_configuration {
    ##For testing service reachability wthout ALB
    # assign_public_ip = true
    # subnets         = [for sn in aws_subnet.public : sn.id]
    ##Switch to public subnets once ALB is set up
    subnets         = [for sn in aws_subnet.private : sn.id]
    security_groups = [aws_security_group.ecs_access.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "proxy"
    container_port   = 8000
  }
}

resource "aws_ecs_task_definition" "taskdef" {
  family                   = local.prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  container_definitions = jsonencode(
    [
      {
        name              = "api"
        image             = var.ecr_app_image
        essential         = true
        memoryReservation = 256
        user              = "django-user"
        environment = [
          {
            name  = "DJANGO_SECRET_KEY"
            value = var.django_secret_key
          },
          {
            name  = "DB_HOST"
            value = aws_db_instance.main.address
          },
          {
            name  = "DB_NAME"
            value = aws_db_instance.main.db_name
          },
          {
            name  = "DB_USER"
            value = aws_db_instance.main.username
          },
          {
            name  = "DB_PASS"
            value = aws_db_instance.main.password
          },
          {
            name  = "ALLOWED_HOSTS"
            value = aws_route53_record.app_cname_record.fqdn
          }
        ]
        mountPoints = [
          {
            readOnly      = false
            containerPath = "/vol/web/static"
            sourceVolume  = "static"
          },
          {
            readOnly      = false
            containerPath = "/vol/web/media"
            sourceVolume  = "efs-media"
          }
        ],
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
            awslogs-region        = data.aws_region.current.region
            awslogs-stream-prefix = "api"
          }
        }
      },
      {
        name              = "proxy"
        image             = var.ecr_proxy_image
        essential         = true
        memoryReservation = 256
        user              = "nginx"
        portMappings = [
          {
            containerPort = 8000
            hostPort      = 8000
          }
        ]
        environment = [
          {
            name  = "APP_HOST"
            value = "127.0.0.1"
          }
        ]
        mountPoints = [
          {
            readOnly      = true
            containerPath = "/vol/static"
            sourceVolume  = "static"
          },
          {
            readOnly      = true
            containerPath = "/vol/media"
            sourceVolume  = "efs-media"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
            awslogs-region        = data.aws_region.current.region
            awslogs-stream-prefix = "proxy"
          }
        }
      }
    ]
  )
  volume {
    name = "static"
  }
  volume {
    name = "efs-media"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.media.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.media.id
        iam             = "DISABLED"
      }
    }
  }
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

# Security Group to implement Access Control for the ECS service
resource "aws_security_group" "ecs_access" {
  name        = "${local.prefix}-ecs-access"
  description = "Access rules for the ECS service"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true #Fix "Still destroying..." issue
  }
  tags = {
    Name = "${local.prefix}-ecs-access"
  }
}
resource "aws_vpc_security_group_egress_rule" "outbound_endpoints_access" {
  security_group_id = aws_security_group.ecs_access.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound HTTPS traffic to the endpoints"
}
resource "aws_vpc_security_group_egress_rule" "outbound_postgres_access" {
  for_each          = toset(local.private_cidrs)
  security_group_id = aws_security_group.ecs_access.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  description       = "Outbound PostgreSQL traffic for RDS connectivity inside private subnets"
}
resource "aws_vpc_security_group_egress_rule" "outbound_efs_access" {
  for_each          = toset(local.private_cidrs)
  security_group_id = aws_security_group.ecs_access.id
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  description       = "Outbound NFS traffic to the EFS storage inside private subnets"
}
resource "aws_vpc_security_group_ingress_rule" "inbound_app_access" {
  security_group_id            = aws_security_group.ecs_access.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_access.id
  description                  = "Inbound internet traffic from ALB to the application"
}


# IAM resources needed by the ECS service
##1. Task Role & permissions needed by the application
resource "aws_iam_role" "task_role" {
  name               = "${local.prefix}-task-role"
  description        = "Role assumed by the containers within a task for the application"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}
resource "aws_iam_policy" "task_role_policy" {
  name        = "${aws_iam_role.task_role.name}-policy"
  description = "Allow accessing the AWS services needed for the application"
  policy      = data.aws_iam_policy_document.task_role_policy.json
}
data "aws_iam_policy_document" "task_role_policy" {
  statement {
    sid    = "ManageSSMChannel"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "task_role_policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

##2. Task Execution Role & permissions needed by ECS to manage and run the application
resource "aws_iam_role" "task_execution_role" {
  name               = "${local.prefix}-task-execution-role"
  description        = "Role assumed by the ECS service to manage the task lifecycle"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}
resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${aws_iam_role.task_execution_role.name}-policy"
  description = "Allow ECS to retrieve images and add to logs"
  policy      = data.aws_iam_policy_document.task_execution_role_policy.json
}
data "aws_iam_policy_document" "task_execution_role_policy" {
  statement {
    sid    = "AccessECRAndCWLogs"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

# Trust policy for the Task Role & the Task Execution Role
data "aws_iam_policy_document" "task_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

#Cloudwatch log group
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${terraform.workspace}/${var.project}"
}