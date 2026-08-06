output "frontend_link" {
  value = aws_s3_bucket.frontend_bucket.website_endpoint
}
