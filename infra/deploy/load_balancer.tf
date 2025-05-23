# ALB (Application Load Balancer) setup
resource "aws_lb" "api" {
  name               = "${local.prefix}-alb"
  load_balancer_type = "application"
  subnets            = [for sn in aws_subnet.public : sn.id]
  security_groups    = [aws_security_group.alb_access.id]
}
resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "api_https" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_target_group" "api" {
  name        = "${local.prefix}-tg"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  port        = 8000
  health_check {
    path = "/api/health-check/"
  }
}


# Security Group to implement Access Control for the ALB
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
