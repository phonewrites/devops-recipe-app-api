locals {
  azs_for_public_subnets  = slice(data.aws_availability_zones.available.names, 0, length(local.public_cidrs))
  azs_for_private_subnets = slice(data.aws_availability_zones.available.names, 0, length(local.private_cidrs))

  # CIDRs for different AZs 
  public_cidrs = [ #Subnets begin in 3rd octet at 0,1...
    "10.127.0.0/24",
    "10.127.1.0/24"
  ]
  private_cidrs = [ #Subnets begin halfway in 3rd octet from 128,129...
    "10.127.128.0/24",
    "10.127.129.0/24"
  ]

  # Map of interface endpoints
  interface_endpoints = {
    ecr        = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
    dkr        = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
    cloudwatch = "com.amazonaws.${data.aws_region.current.region}.logs"
    ssm        = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"
  }
}

# Custom VPC + Internet Gateway needed for inbound access to the ALB
resource "aws_vpc" "main" {
  cidr_block           = "10.127.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.prefix}-vpc"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.prefix}-igw"
  }
}

# Public Subnets for load balancer public access
resource "aws_subnet" "public" {
  for_each = {
    for idx, az in local.azs_for_public_subnets :
    az => local.public_cidrs[idx]
  }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.prefix}-pub-${substr(each.key, length(each.key) - 1, 1)}"
  }
}
resource "aws_route_table" "public" {
  for_each = aws_subnet.public
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${local.prefix}-pub-${substr(each.key, length(each.key) - 1, 1)}"
  }
}
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}
resource "aws_route" "public_internet_access" {
  for_each               = aws_route_table.public
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Private Subnets for internal access only
resource "aws_subnet" "private" {
  for_each = {
    for idx, az in local.azs_for_private_subnets :
    az => local.private_cidrs[idx]
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${local.prefix}-pri-${substr(each.key, length(each.key) - 1, 1)}"
  }
}

# AWS VPC Endpoints setup for ECR, CloudWatch, Systems Manager & S3
resource "aws_security_group" "endpoint_access" {
  name        = "${local.prefix}-endpoint-access" #test name change
  description = "Access to VPC endpoints"
  vpc_id      = aws_vpc.main.id
  # ingress {
  #   cidr_blocks = [aws_vpc.main.cidr_block]
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  # }
  lifecycle {
    create_before_destroy = true #Fix "Still destroying..." issue
  }
  tags = {
    Name = "${local.prefix}-endpoint-access"
  }
}
resource "aws_vpc_security_group_ingress_rule" "endpoint_access" {
  security_group_id = aws_security_group.endpoint_access.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS inbound"
}

resource "aws_vpc_endpoint" "interface_endpoint" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for sn in aws_subnet.private : sn.id]
  security_group_ids  = [aws_security_group.endpoint_access.id]
  tags = {
    Name = "${local.prefix}-${each.key}-endpoint"
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_vpc.main.default_route_table_id
  ]
  tags = {
    Name = "${local.prefix}-s3-endpoint"
  }
}
