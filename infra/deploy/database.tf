# RDS Database Instance & related resources
resource "aws_db_instance" "main" {
  identifier                 = "${local.prefix}-db"
  db_name                    = replace(local.prefix, "-", "")
  allocated_storage          = 20
  storage_type               = "gp2"
  engine                     = "postgres"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.main.name
  multi_az                   = false
  backup_retention_period    = 0
  vpc_security_group_ids     = [aws_security_group.rds_inbound_access.id]
  tags = {
    Name = "${local.prefix}-db"
  }
  lifecycle { #Deletes & replaces the DB instance when SG updates
    replace_triggered_by = [aws_security_group.rds_inbound_access]
  }
}
resource "aws_db_subnet_group" "main" {
  name       = "${local.prefix}-main"
  subnet_ids = [for sn in aws_subnet.private : sn.id]
  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}
resource "aws_security_group" "rds_inbound_access" {
  name        = "${local.prefix}-rds-inbound-access"
  description = "Access rules for the RDS DB instance"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true #Fix "Still destroying..." issue
  }
  tags = {
    Name = "${local.prefix}-rds-inbound-access"
  }
}
resource "aws_vpc_security_group_ingress_rule" "rds_inbound_access" {
  # for_each          = toset(local.private_cidrs)
  security_group_id = aws_security_group.rds_inbound_access.id
  # cidr_ipv4         = each.value
  referenced_security_group_id = aws_security_group.ecs_access.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL inbound access from ECS"
}

