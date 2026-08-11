resource "aws_security_group" "backend" {
  name   = "${var.vpc_name}-backend-sg"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  dynamic "ingress" {
    for_each = var.ingress_rules_backend
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
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

