########## TESTING ####################

# EFS resources for persistent media storage
resource "aws_efs_file_system" "main" {
  encrypted = true #Encryption at rest
  tags = {
    Name = "${local.prefix}-media"
  }
}
resource "aws_efs_mount_target" "main" {
  for_each        = aws_subnet.private
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs_access.id]
}

# Security Group to implement Access Control to EFS
resource "aws_security_group" "efs_access" {
  name        = "${local.prefix}-efs-access"
  description = "Access rules for the EFS service"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true #Fix "Still destroying..." issue
  }
  tags = {
    Name = "${local.prefix}-efs-access"
  }
  #   ingress {
  #     from_port = 2049
  #     to_port   = 2049
  #     protocol  = "tcp"

  #     security_groups = [
  #       aws_security_group.ecs_service.id
  #     ]
  #   }
}
resource "aws_vpc_security_group_ingress_rule" "inbound_efs_access" {
  security_group_id            = aws_security_group.efs_access.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_access.id
  description                  = "Inbound NFS traffic from application"
}


########## TESTING ####################
