resource "aws_lb_target_group" "backend" {
  name     = "${var.vpc_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"
  health_check {
    enabled             = true
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "8080"
    matcher             = "200"
    interval            = "30"
    timeout             = "5"
    healthy_threshold   = "2"
    unhealthy_threshold = "3"
  }
}


resource "aws_lb" "backend" {
  name                             = "${var.vpc_name}-backend-alb"
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb.id]
  subnets                          = [for subnet in aws_subnet.public : subnet.id]
  enable_cross_zone_load_balancing = true
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
      values = ["/api", "/api/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}