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
  availability_zone       = element(data.aws_availability_zones.available.names, tonumber(each.key) - 1)
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

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.vpc_name}-subnet-group"
  subnet_ids = [for subnet in aws_subnet.database : subnet.id]
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.vpc_name}-redis-cluster"
  subnet_ids = [for subnet in aws_subnet.elasticache : subnet.id]
}
