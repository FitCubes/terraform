resource "aws_cloudwatch_log_group" "asg_docker" {
  name              = var.log_group_name
  retention_in_days = 7
}

resource "aws_sns_topic" "alerts" {
  name = "${var.vpc_name}-alerts"
}

resource "aws_sns_topic_subscription" "send_emails" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "asg_zero" {
  alarm_name        = "instance-high-cpu-usage"
  metric_name       = "CPUUtilization"
  namespace         = "AWS/EC2"
  alarm_description = "CPU utilization of instance > 80%"

  evaluation_periods = 3
  period             = 60
  statistic          = "Average"

  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}


resource "aws_cloudwatch_metric_alarm" "zero_asg" {
  alarm_name        = "zero-instances-in-service"
  metric_name       = "GroupInServiceInstances"
  namespace         = "AWS/AutoScaling"
  alarm_description = "0 instance right now"

  evaluation_periods = 2
  period             = 60
  statistic          = "Average"

  threshold           = 1
  comparison_operator = "LessThanThreshold"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}


resource "aws_cloudwatch_metric_alarm" "high_db_cpu" {
  alarm_name        = "rds-high-cpu"
  metric_name       = "CPUUtilization"
  namespace         = "AWS/RDS"
  alarm_description = "CPU utilization on RDS > 80%"

  evaluation_periods = 2
  period             = 60
  statistic          = "Average"

  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}


resource "aws_cloudwatch_metric_alarm" "high_latency_backend" {
  alarm_name        = "high-latency"
  metric_name       = "TargetResponseTime"
  namespace         = "AWS/ApplicationELB"
  alarm_description = "backend response time p95 higher than 1s"

  period              = 60
  extended_statistic = "p95"
  threshold           = 1.0
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = var.alb_suffix
    TargetGroup  = var.target_group_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}


resource "aws_cloudwatch_metric_alarm" "high_5xx_count" {
  alarm_name = "high-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  threshold = 5 # %

  alarm_actions = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "count_errors"
    metric {
      namespace = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period = 300
      stat = "Sum"
      dimensions = {
        LoadBalancer = var.alb_suffix
        TargetGroup  = var.target_group_suffix
      }
    }
  }
  metric_query {
    id = "count_total"
    metric {
      namespace = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period = 300
      stat = "Sum"
      dimensions = {
        LoadBalancer = var.alb_suffix
        TargetGroup  = var.target_group_suffix
      }
    }
  }
  metric_query {
    id = "count"
    expression = "count_errors / count_total * 100"
    return_data = true
  }
}
