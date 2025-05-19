## TO DO: ADD LBs + LISTENERS + TARGET GROUPS, ETC.

resource "aws_security_group" "alb_access" {
  description = "Access rules for the Application Load Balancer"
  name        = "${local.prefix}-alb-access"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true #Fix "Still destroying..." issue
  }
  tags = {
    Name = "${local.prefix}-alb-access"
  }
  #   ingress {
  #     protocol    = "tcp"
  #     from_port   = 80
  #     to_port     = 80
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  #   ingress {
  #     protocol    = "tcp"
  #     from_port   = 443
  #     to_port     = 443
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  #   egress {
  #     protocol    = "tcp"
  #     from_port   = 8000
  #     to_port     = 8000
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
}

resource "aws_vpc_security_group_ingress_rule" "inbound_http_access" {
  security_group_id = aws_security_group.alb_access.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Inbound HTTP traffic from internet"
}
resource "aws_vpc_security_group_ingress_rule" "inbound_https_access" {
  security_group_id = aws_security_group.alb_access.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Inbound HTTPS traffic from internet"
}
resource "aws_vpc_security_group_egress_rule" "outbound_app_access" {
  security_group_id = aws_security_group.alb_access.id
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound traffic from the application to internet"
}
