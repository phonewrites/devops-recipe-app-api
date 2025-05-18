# ECS Cluster for running app on Fargate.

resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-cluster"
}