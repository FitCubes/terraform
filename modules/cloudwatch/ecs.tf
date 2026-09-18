resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name = "ecs-high-cpu"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  alarm_description = "CPU utiliaztion on ECS service > 70%"

  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"

  threshold           = 70
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = [ aws_sns_topic.alerts.arn ]
}


resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name = "ecs-high-memory"
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  alarm_description = "Memory utiliaztion on ECS service > 80%"

  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"

  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = [ aws_sns_topic.alerts.arn ]
}

resource "aws_cloudwatch_metric_alarm" "task_alive" {
  alarm_name = "zero-tasks"
  metric_name = "LiveTaskCount"
  namespace = "AWS/ECS"
  alarm_description = "Zero tasks in service"

  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"

  threshold           = 1
  comparison_operator = "LessThanThreshold"
  dimensions = {
    ServiceName = var.ecs_service_name
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = [ aws_sns_topic.alerts.arn ]
}
