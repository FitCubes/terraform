resource "aws_cloudwatch_log_group" "asg_docker" {
  name              = var.log_group_name
  retention_in_days = 7
}


resource "aws_cloudwatch_metric_alarm" "asg_zero" {
  alarm_name = "instance-high-cpu-usage"
  metric_name = "cpu_usage_idle"
  namespace = var.metrics_namespace

  evaluation_periods = 3
  period = 60
  statistic = "Average"

  threshold = 20
  comparison_operator = "LessThanOrEqualToThreshold"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_asg.name
  }
}
