
resource "aws_cloudwatch_metric_alarm" "high_latency_backend" {
  alarm_name        = "high-latency"
  metric_name       = "TargetResponseTime"
  namespace         = "AWS/ApplicationELB"
  alarm_description = "backend response time p95 higher than 1s"

  treat_missing_data = "notBreaching"

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

  treat_missing_data = "notBreaching"

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
