resource "aws_cloudwatch_log_group" "backend_ecs" {
  name              = var.log_group_name_ecs
  retention_in_days = 3
}

# ======================= SG =============================
resource "aws_security_group" "ecs_ec2" {
  name   = "${var.vpc_name}-ecs-ec2-backend"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 32768
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.alb.id
    ]
  }
}

# ======================= TARGET GROUPS =============================

resource "aws_lb_target_group" "ecs_ec2_blue" {
  name        = "${var.vpc_name}-ecs-blue-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check {
    enabled             = true
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = "30"
    timeout             = "5"
    healthy_threshold   = "2"
    unhealthy_threshold = "3"
  }
}

resource "aws_lb_target_group" "ecs_ec2_green" {
  name        = "${var.vpc_name}-ecs-green-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check {
    enabled             = true
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = "30"
    timeout             = "5"
    healthy_threshold   = "2"
    unhealthy_threshold = "3"
  }
}

# ======================= POLICIES =============================

#  === EC2 ===
data "aws_iam_policy_document" "ecs_ec2_instance_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_ec2_role" {
  name               = "${var.vpc_name}-ecs-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_ec2_instance_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role_policy" {
  role       = aws_iam_role.ecs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role_policy_smm" {
  role       = aws_iam_role.ecs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_ec2_instance_profile" {
  name = "${var.vpc_name}-ecs-ec2-instance-profile"
  role = aws_iam_role.ecs_ec2_role.name
}

#  === ECS ===
#  ECS Service
resource "aws_iam_service_linked_role" "ecs_service_role" {
  aws_service_name = "ecs.amazonaws.com"
}
# Task Execution
data "aws_iam_policy_document" "ecs_task_definition" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.vpc_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_definition.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_default" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution_ssm" {
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      aws_ssm_parameter.db_password.arn,
      aws_ssm_parameter.db_username.arn,
      aws_ssm_parameter.jwt_secret.arn,
      aws_ssm_parameter.frontend_url.arn,
      aws_ssm_parameter.redis_address.arn,
      aws_ssm_parameter.datasource_url.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_task_execution_ssm" {
  name   = "${var.vpc_name}-ecs-task-execution-get-ssm"
  policy = data.aws_iam_policy_document.ecs_task_execution_ssm.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm.arn
}

# ECS SERVICE START LAMBDA
data "aws_iam_policy_document" "role_ecs_run_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_invoke_lambda" {
  name               = "${var.vpc_name}-ecs-allow-invoke-lambda"
  assume_role_policy = data.aws_iam_policy_document.role_ecs_run_lambda.json
}

data "aws_iam_policy_document" "ecs_allow_invoke" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.smoke_lambda.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_allow_invoke_lambda" {
  name   = "${var.vpc_name}-allow-invoke-lambda"
  policy = data.aws_iam_policy_document.ecs_allow_invoke.json
}

resource "aws_iam_role_policy_attachment" "ecs_allow_invoke_lambda" {
  role       = aws_iam_role.ecs_invoke_lambda.name
  policy_arn = aws_iam_policy.ecs_allow_invoke_lambda.arn
}

# ECS SERVICE LB
data "aws_iam_policy_document" "role_ecs_lb" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_lb" {
  name               = "${var.vpc_name}-ecs-lb"
  assume_role_policy = data.aws_iam_policy_document.role_ecs_lb.json
}

data "aws_iam_policy_document" "ecs_lb" {
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",

    ]
    resources = [
      aws_lb_listener.backend.arn,
      aws_lb_listener_rule.forward_to_api.arn,
      aws_lb_listener_rule.test.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      aws_lb_target_group.ecs_ec2_blue.arn,
      aws_lb_target_group.ecs_ec2_green.arn
    ]
  }
}

resource "aws_iam_policy" "ecs_lb" {
  name   = "${var.vpc_name}-ecs-lb"
  policy = data.aws_iam_policy_document.ecs_lb.json
}

resource "aws_iam_role_policy_attachment" "ecs_lb" {
  role       = aws_iam_role.ecs_lb.name
  policy_arn = aws_iam_policy.ecs_lb.arn
}

# ======================= INSTANCE =============================
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}


resource "aws_launch_template" "ecs_ec2" {
  name = "${var.vpc_name}-ecs-ec2-backend"

  image_id                             = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_ec2_instance_profile.arn
  }
  user_data = base64encode(<<-EOF
    #! /bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.backend.name} >> /etc/ecs/ecs.config
    EOF
  )
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_ec2.id]
  }
}

resource "aws_autoscaling_group" "ecs_ec2_capacity" {
  name                  = "${var.vpc_name}-asg-ecs-ec2"
  min_size              = 0
  max_size              = 10
  desired_capacity      = 1
  protect_from_scale_in = true
  vpc_zone_identifier   = [for subnet in aws_subnet.public : subnet.id]
  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "ECSProvisioned"
    propagate_at_launch = true
  }
}

# ======================= ECS =============================
resource "aws_ecs_capacity_provider" "ecs_backend" {
  name = "${var.vpc_name}-ecs-ec2-capacity-provider-backend"
  auto_scaling_group_provider {
    managed_termination_protection = "ENABLED"
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_ec2_capacity.arn
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
}
# Cluster
resource "aws_ecs_cluster" "backend" {
  name = "${var.vpc_name}-ecs-cluster"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/${var.vpc_name}/ecs/cluster"
  retention_in_days = 3
}

resource "aws_ecs_cluster_capacity_providers" "ecs_ec2_capacity" {
  cluster_name       = aws_ecs_cluster.backend.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_backend.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_backend.name
    weight            = 1
  }
}
# Task
resource "aws_ecs_task_definition" "backend" {
  family             = "backend"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "backend-java"
      essential = true
      image     = "${var.repository_name}:sha-4846ce0"

      cpu               = 512
      memoryReservation = 512
      memory            = 1024

      portMappings = [{
        containerPort = 8080
        hostPort      = 0
        protocol      = "tcp"
      }]
      environment = [
        {
          name  = "SPRING_DATA_REDIS_PORT"
          value = tostring(aws_elasticache_cluster.redis.port)
        }
      ]
      secrets = [
        {
          name      = "SPRING_DATASOURCE_URL"
          valueFrom = aws_ssm_parameter.datasource_url.arn
        },
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = aws_ssm_parameter.db_username.arn
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        },
        {
          name      = "SPRING_DATA_REDIS_HOST"
          valueFrom = aws_ssm_parameter.redis_address.arn
        },
        {
          name      = "FRONTEND_URL"
          valueFrom = aws_ssm_parameter.frontend_url.arn
        },
        {
          name      = "JWT_SECRET",
          valueFrom = aws_ssm_parameter.jwt_secret.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_ecs.name,
          "awslogs-region"        = var.region,
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}
# Service
resource "aws_ecs_service" "backend" {
  name    = "${var.vpc_name}-ecs-service"
  cluster = aws_ecs_cluster.backend.id

  iam_role                           = aws_iam_service_linked_role.ecs_service_role.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  task_definition                    = aws_ecs_task_definition.backend.arn

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_ec2_blue.arn
    container_name   = "backend-java"
    container_port   = 8080
    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.ecs_ec2_green.arn
      production_listener_rule   = aws_lb_listener_rule.forward_to_api.arn
      test_listener_rule         = aws_lb_listener_rule.test.arn
      role_arn                   = aws_iam_role.ecs_lb.arn
    }
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_backend.name
    base              = 1
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_configuration {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = 2


    lifecycle_hook {
      hook_target_arn  = aws_lambda_function.smoke_lambda.arn
      lifecycle_stages = ["POST_TEST_TRAFFIC_SHIFT"]
      role_arn         = aws_iam_role.ecs_invoke_lambda.arn
    }
  }

  lifecycle {
    ignore_changes = [
      # task_definition,
      desired_count
    ]
  }
}

# AutoScaling
resource "aws_appautoscaling_target" "ecs_scale" {
  min_capacity       = 1
  max_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.backend.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scaling_cpu" {
  name               = "${var.vpc_name}-ecs-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_scale.id
  scalable_dimension = aws_appautoscaling_target.ecs_scale.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scale.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_scaling_memory" {
  name               = "${var.vpc_name}-ecs-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_scale.id
  scalable_dimension = aws_appautoscaling_target.ecs_scale.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scale.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 85

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
