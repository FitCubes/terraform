resource "aws_sns_topic" "alerts" {
  name = "${var.vpc_name}-alerts"
}

resource "aws_sns_topic_subscription" "send_emails" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
