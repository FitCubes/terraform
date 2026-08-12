data "cloudflare_ip_ranges" "ip" {

}

resource "aws_security_group" "alb" {
  name   = "${var.vpc_name}-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = data.cloudflare_ip_ranges.ip.ipv4_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend" {
  name   = "${var.vpc_name}-backend-sg"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  tags = {
    "Name" = "${var.vpc_name}-backend-sg"
  }
}


resource "aws_security_group" "db" {
  name   = "${var.vpc_name}-db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.vpc_name}-db-sg"
  }
}


resource "aws_security_group" "redis" {
  name   = "${var.vpc_name}-redis-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = "6379"
    to_port         = "6379"
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
}

