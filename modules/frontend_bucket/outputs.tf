output "frontend_link" {
  value = aws_s3_bucket_website_configuration.frontend_bucket.website_endpoint
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend_bucket.arn
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend_bucket.bucket
}