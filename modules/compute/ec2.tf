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
    jwt_secret_ssm_name      = aws_ssm_parameter.jwt_secret.name,
    elasticache_cluster_port = aws_elasticache_cluster.redis.port
    db_port                  = aws_db_instance.main.port
    region                   = var.region
    metrics_namespace        = var.metrics_namespace
    log_group_name           = var.log_group_name
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
