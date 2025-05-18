# ECS Cluster for running app on Fargate
resource "aws_ecs_cluster" "main" {
  name = local.prefix
}

######### TESTING ################################
# resource "aws_ecs_service" "service" {
#   name                   = "${local.prefix}-service"
#   cluster                = aws_ecs_cluster.main.name
#   task_definition        = aws_ecs_task_definition.taskdef.family
#   desired_count          = 1
#   launch_type            = "FARGATE"
#   platform_version       = "1.4.0"
#   enable_execute_command = true
#   network_configuration {
#     assign_public_ip = true
#     subnets = [for sn in aws_subnet.aws_subnet.public : sn.id]
#     security_groups = [aws_security_group.ecs_service_access.id]
#   }
# }

# resource "aws_ecs_task_definition" "taskdef" {
#   family                   = "${local.prefix}"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = 256
#   memory                   = 512
#   execution_role_arn       = aws_iam_role.task_execution_role.arn
#   task_role_arn            = aws_iam_role.task_role.arn
#   container_definitions = jsonencode(
#     [
#       {
#         name              = "api"
#         image             = var.ecr_app_image
#         essential         = true
#         memoryReservation = 256
#         user              = "django-user"
#         environment = [
#           {
#             name  = "DJANGO_SECRET_KEY"
#             value = var.django_secret_key
#           },
#           {
#             name  = "DB_HOST"
#             value = aws_db_instance.main.address
#           },
#           {
#             name  = "DB_NAME"
#             value = aws_db_instance.main.db_name
#           },
#           {
#             name  = "DB_USER"
#             value = aws_db_instance.main.username
#           },
#           {
#             name  = "DB_PASS"
#             value = aws_db_instance.main.password
#           },
#           {
#             name  = "ALLOWED_HOSTS"
#             value = "*"
#           }
#         ]
#         mountPoints = [
#           {
#             readOnly      = false
#             containerPath = "/vol/web/static"
#             sourceVolume  = "static"
#           }
#         ],
#         logConfiguration = {
#           logDriver = "awslogs"
#           options = {
#             awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
#             awslogs-region        = data.aws_region.current.name
#             awslogs-stream-prefix = "api"
#           }
#         }
#       },
#       {
#         name              = "proxy"
#         image             = var.ecr_proxy_image
#         essential         = true
#         memoryReservation = 256
#         user              = "nginx"
#         portMappings = [
#           {
#             containerPort = 8000
#             hostPort      = 8000
#           }
#         ]
#         environment = [
#           {
#             name  = "APP_HOST"
#             value = "127.0.0.1"
#           }
#         ]
#         mountPoints = [
#           {
#             readOnly      = true
#             containerPath = "/vol/static"
#             sourceVolume  = "static"
#           }
#         ]
#         logConfiguration = {
#           logDriver = "awslogs"
#           options = {
#             awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
#             awslogs-region        = data.aws_region.current.name
#             awslogs-stream-prefix = "proxy"
#           }
#         }
#       }
#     ]
#   )
#   volume {
#     name = "static"
#   }
#   runtime_platform {
#     operating_system_family = "LINUX"
#     cpu_architecture        = "X86_64"
#   }
# }
######### TESTING ################################

resource "aws_security_group" "ecs_access" {
  name        = "${local.prefix}-ecs-access"
  description = "Access rules for the ECS service"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true #Fix "Still destroying..." issue
  }
  # Outbound access to endpoints
#   egress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   # RDS connectivity
#   egress {
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = local.private_cidrs
#   }
#   # HTTP inbound access
#   ingress {
#     from_port   = 8000
#     to_port     = 8000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  tags = {
    Name = "${local.prefix}-ecs-access"
  }
}

######### TESTING ################################
resource "aws_vpc_security_group_egress_rule" "endpoints_outbound_access" {
  security_group_id = aws_security_group.ecs_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Outbound access to endpoints"
}
resource "aws_vpc_security_group_egress_rule" "rds_outbound_access" {
  for_each          = toset(local.private_cidrs)
  security_group_id = aws_security_group.ecs_access.id
    #cidr_ipv4         = "0.0.0.0/0"
  cidr_ipv4         = each.value
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "Outbound for RDS connectivity"
}
resource "aws_vpc_security_group_ingress_rule" "http_inbound_access" {
  security_group_id = aws_security_group.ecs_access.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  description       = "HTTP inbound access"
}
######### TESTING ################################









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



