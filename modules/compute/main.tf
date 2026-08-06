resource aws_vpc main {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "${var.vpc_name}-vpc"
    }
}

resource aws_subnet public {
    for_each = toset(var.azs)
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    availability_zone = each.value
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.vpc_name}-public-az1"
    }
}

resource aws_subnet private {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "en-north-1a"
    tags = {
        Name = "${var.vpc_name}-private-az1"
    }
}

resource aws_subnet private {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "en-north-1b"
    tags = {
        Name = "${var.vpc_name}-private-az2"
    }
}

resource aws_subnet private {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.5.0/24"
    availability_zone = "en-north-1c"
    tags = {
        Name = "${var.vpc_name}-private-az3"
    }
}


resource aws_internet_gateway main {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.vpc_name}-igw"
    }
}

resource aws_route_table main {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}

resource aws_route_table_association main {
    count = length(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.main.id
}