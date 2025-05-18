# ECS Cluster for running app on Fargate.
resource "aws_ecs_cluster" "main" {
  name = local.prefix
}

#########

# Task Role & permissions needed by the application
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

# Task Execution Role & permissions needed by ECS to manage and run the application
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




