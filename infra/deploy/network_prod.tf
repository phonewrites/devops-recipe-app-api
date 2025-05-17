# Custom VPC + Internet Gateway needed for inbound access to the ALB
resource "aws_vpc" "main" {
  cidr_block           = "10.127.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.prefix}-vpc"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-igw"
  }
}

############## TRY DRY
# # Public Subnets for load balancer public access
# # AZ a
# resource "aws_subnet" "public_a" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = each.value
#   map_public_ip_on_launch = true
#   availability_zone       = data.aws_availability_zones.available.names[0]
#   tags = {
#     Name = "${var.prefix}-pub-a"
#   }
# }
# resource "aws_route_table" "public_a" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "${var.prefix}-pub-a"
#   }
# }
# resource "aws_route_table_association" "public_a" {
#   subnet_id      = aws_subnet.public_a.id
#   route_table_id = aws_route_table.public_a.id
# }
# resource "aws_route" "public_internet_access_a" {
#   route_table_id         = aws_route_table.public_a.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.main.id
# }
# # AZ b
# resource "aws_subnet" "public_b" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.127.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = data.aws_availability_zones.available.names[1]
#   tags = {
#     Name = "${var.prefix}-pub-b"
#   }
# }
# resource "aws_route_table" "public_b" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "${var.prefix}-pub-b"
#   }
# }
# resource "aws_route_table_association" "public_b" {
#   subnet_id      = aws_subnet.public_b.id
#   route_table_id = aws_route_table.public_b.id
# }
# resource "aws_route" "public_internet_access_b" {
#   route_table_id         = aws_route_table.public_b.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.main.id
# }

# # Private Subnets for internal access only
# # AZ a
# resource "aws_subnet" "private_a" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.127.128.0/24"
#   availability_zone = data.aws_availability_zones.available.names[0]
#   tags = {
#     Name = "${var.prefix}-pri-a"
#   }
# }
# # AZ b
# resource "aws_subnet" "private_b" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.127.129.0/24"
#   availability_zone = data.aws_availability_zones.available.names[1]
#   tags = {
#     Name = "${var.prefix}-pri-b"
#   }
# }
# AWS VPC Endpoints setup for ECR, CloudWatch, S3 & Systems Manager
# resource "aws_security_group" "endpoint_access" {
#   description = "Access to endpoints"
#   name        = "${var.prefix}-endpoint-access"
#   vpc_id      = aws_vpc.main.id
#   ingress {
#     cidr_blocks = [aws_vpc.main.cidr_block]
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#   }
# }

# resource "aws_vpc_endpoint" "ecr" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   subnet_ids = [
#     aws_subnet.private_a.id,
#     aws_subnet.private_b.id,
#   ]
#   security_group_ids = [
#     aws_security_group.endpoint_access.id
#   ]
#   tags = {
#     Name = "${var.prefix}-ecr-endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "dkr" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   subnet_ids = [
#     aws_subnet.private_a.id,
#     aws_subnet.private_b.id,
#   ]
#   security_group_ids = [
#     aws_security_group.endpoint_access.id
#   ]
#   tags = {
#     Name = "${var.prefix}-dkr-endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "cloudwatch" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.region}.logs"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   subnet_ids = [
#     aws_subnet.private_a.id,
#     aws_subnet.private_b.id,
#   ]
#   security_group_ids = [
#     aws_security_group.endpoint_access.id
#   ]
#   tags = {
#     Name = "${var.prefix}-cloudwatch-endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   subnet_ids = [
#     aws_subnet.private_a.id,
#     aws_subnet.private_b.id,
#   ]
#   security_group_ids = [
#     aws_security_group.endpoint_access.id
#   ]
#   tags = {
#     Name = "${var.prefix}-ssm-endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids = [
#     aws_vpc.main.default_route_table_id
#   ]
#   tags = {
#     Name = "${var.prefix}-s3-endpoint"
#   }
# }

############## TRY DRY
locals {
  azs_for_public_subnets  = slice(data.aws_availability_zones.available.names, 0, length(local.public_cidrs))
  azs_for_private_subnets = slice(data.aws_availability_zones.available.names, 0, length(local.private_cidrs))

  # /24‐sized CIDRs for different AZs
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
    Name = "${var.prefix}-pub-${substr(each.key, length(each.key) - 1, 1)}"
  }
}
resource "aws_route_table" "public" {
  for_each = aws_subnet.public
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-pub-${substr(each.key, length(each.key) - 1, 1)}"
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
    Name = "${var.prefix}-pri-${substr(each.key, length(each.key) - 1, 1)}"
  }
}

# AWS VPC Endpoints setup for ECR, CloudWatch, Systems Manager & S3
resource "aws_security_group" "endpoint_access" {
  description = "Access to endpoints"
  name        = "${var.prefix}-endpoint-access"
  vpc_id      = aws_vpc.main.id
  ingress {
    cidr_blocks = [aws_vpc.main.cidr_block]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
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
    Name = "${var.prefix}-${each.key}-endpoint"
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
    Name = "${var.prefix}-s3-endpoint"
  }
}



