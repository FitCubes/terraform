resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  for_each                = var.subnets_public_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[each.key]
  tags = {
    Name = "${var.vpc_name}-public-az${each.key}"
  }
}


resource "aws_subnet" "database" {
  for_each                = var.subnets_database_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[each.key]
  tags = {
    Name = "${var.vpc_name}-database-az${each.key}"
  }
}

resource "aws_subnet" "elasticache" {
  for_each                = var.elasticache_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[each.key]
  tags = {
    Name = "${var.vpc_name}-elasticache-az${each.key}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}


resource "aws_route_table_association" "public2" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}


# resource "aws_security_group" "main" {
#   name        = "${var.vpc_name}-sg"
#   vpc_id      = aws_vpc.main.id

#   dynamic "ingress" {
#     for_each = var.ingress_rules
#     content {
#       from_port   = ingress.value.from_port
#       to_port     = ingress.value.to_port
#       protocol    = ingress.value.protocol
#       cidr_blocks = ingress.value.cidr_blocks
#     }
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_key_pair" "main" {
#   key_name   = "${var.vpc_name}-key"
#   public_key = file(var.public_key_path)
# }


# resource "aws_instance" "web" {
#   ami             = var.ami
#   instance_type   = var.instance_type
#   subnet_id       = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.main.id]
#   key_name        = aws_key_pair.main.key_name

#   user_data = file(var.user_data_path)
#   tags = {
#     Name = "${var.vpc_name}-instance"
#   }
# }

# resource "aws_eip" "main" {
#   domain   = "vpc"
#   instance = aws_instance.web.id
# }
