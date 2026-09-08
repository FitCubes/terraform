resource "aws_cloudwatch_log_group" "asg_docker" {
  name              = var.log_group_name
  retention_in_days = 7
}

resource "aws_sns_topic" "alerts" {
  name = "${var.vpc_name}-alerts"
}

resource "aws_cloudwatch_metric_alarm" "asg_zero" {
  alarm_name  = "instance-high-cpu-usage"
  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"

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
  alarm_name  = "zero-instances-in-service"
  metric_name = "GroupInServiceInstances"
  namespace   = "AWS/AutoScaling"

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

