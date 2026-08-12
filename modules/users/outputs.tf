output "frontend_bucket_user_access_key" {
  value = aws_iam_access_key.frontend_bucket_user_access_key.id
}

output "frontend_bucket_user_access_key_secret" {
  value = aws_iam_access_key.frontend_bucket_user_access_key.secret
}

output "asg_refresh_access_key" {
  value = aws_iam_access_key.asg-refresh.id
}

output "asg_refresh_access_key_secret" {
  value = aws_iam_access_key.asg-refresh.secret
}