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

resource "aws_cloudwatch_metric_alarm" "low_disk_free_space" {
  alarm_name = "low-disk-free-space"
  alarm_description = "Only 5Gb of free space left on RDS"
  comparison_operator = "LessThanThreshold"
  alarm_actions = [aws_sns_topic.alerts.arn]
  evaluation_periods = 2
  threshold = 5 # Gb

  metric_query {
    id = "free_space"
    metric {
      metric_name = "FreeStorageSpace"
      namespace = "AWS/RDS"
      period = 300
      stat = "Average"
      dimensions = {
        DBInstanceIdentifier = var.db_instance_identifier
      }
    }
  }
  metric_query {
    id = "free_space_gb"
    expression = "free_space / 1000000000"
    return_data = true
  }
}
