data "aws_iam_policy_document" "allow_ec2_assume_role" {
  statement {
    sid     = "DefaultEC2Policy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${var.vpc_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.allow_ec2_assume_role.json
}


resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.vpc_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}


resource "aws_cloudwatch_log_group" "asg_backend" {
  name              = var.log_group_name
  retention_in_days = 7
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
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    security_groups = [
      aws_security_group.alb.id
    ]
  }
}

resource "aws_launch_template" "backend" {
  name = "${var.vpc_name}-launch-template"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  image_id = var.ami

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  monitoring {
    enabled = true
  }

  update_default_version = true

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.backend.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.vpc_name}-template"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    db_address_ssm_name      = aws_ssm_parameter.db_address.name,
    db_username_ssm_name     = aws_ssm_parameter.db_username.name,
    db_password_ssm_name     = aws_ssm_parameter.db_password.name,
    redis_address_ssm_name   = aws_ssm_parameter.redis_address.name,
    db_name_ssm_name         = aws_ssm_parameter.db_name.name,
    frontend_url_ssm_name    = aws_ssm_parameter.frontend_url.name,
    jwt_secret_ssm_name      = aws_ssm_parameter.jwt_secret.name,
    elasticache_cluster_port = aws_elasticache_cluster.redis.port,
    db_port                  = aws_db_instance.main.port,
    region                   = var.region,
    log_group_name           = var.log_group_name,
    docker_sha_ssm_name      = aws_ssm_parameter.docker_sha.name
    })
  )
}

resource "aws_autoscaling_group" "ec2_asg" {
  name = "${var.vpc_name}-asg"

  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  vpc_zone_identifier = [for subnet in aws_subnet.public : subnet.id]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  enabled_metrics = ["GroupInServiceInstances"]
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 200
      auto_rollback          = true
    }
  }
}


resource "aws_autoscaling_lifecycle_hook" "ec2_asg" {
  name                   = "${var.vpc_name}-asg-lifecycle-hook"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
  default_result         = "ABANDON"
  heartbeat_timeout      = var.asg_hook_timeout
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}
