output "frontend_bucket_link" {
  value = module.frontend_bucket.frontend_link
}

output "frontend_bucket_user_access_key" {
  value = module.users.frontend_bucket_user_access_key
  sensitive = true
}

output "frontend_bucket_user_access_key_secret" {
  value = module.users.frontend_bucket_user_access_key_secret
  sensitive = true
}