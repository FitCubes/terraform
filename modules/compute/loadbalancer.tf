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


resource "aws_lb" "backend" {
  name                             = "${var.vpc_name}-backend-alb"
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb.id]
  subnets                          = [for subnet in aws_subnet.public : subnet.id]
  enable_cross_zone_load_balancing = true
  tags = {
    Name = "${var.vpc_name}-alb"
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}


resource "aws_lb_listener_rule" "forward_to_api" {
  listener_arn = aws_lb_listener.backend.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/v1", "/api/v1/*"]
    }
  }
  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.ecs_ec2_blue.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.ecs_ec2_green.arn
        weight = 0
      }
    }
  }
  lifecycle {
    ignore_changes = [ action[0].forward ]
  }
}

resource "aws_lb_listener_rule" "test" {
  listener_arn = aws_lb_listener.backend.arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/api/", "/api/*"]
    }
  }
  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.ecs_ec2_blue.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.ecs_ec2_green.arn
        weight = 0
      }
    }
  }
  lifecycle {
    ignore_changes = [ action[0].forward ]
  }
}
