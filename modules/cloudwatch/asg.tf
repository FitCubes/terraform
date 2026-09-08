resource "aws_cloudwatch_metric_alarm" "high_cpu" {
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
