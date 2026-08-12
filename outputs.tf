output "frontend_bucket_link" {
  value = module.frontend_bucket.frontend_link
}

output "frontend_bucket_user_access_key" {
  value     = module.users.frontend_bucket_user_access_key
  sensitive = true
}

output "frontend_bucket_user_access_key_secret" {
  value     = module.users.frontend_bucket_user_access_key_secret
  sensitive = true
}

output "asg_refresh_access_key" {
  value     = module.users.asg_refresh_access_key
  sensitive = true
}

output "asg_refresh_access_key_secret" {
  value     = module.users.asg_refresh_access_key_secret
  sensitive = true
}

output "db_adress" {
  value = module.compute.db_domain
}

output "redis_node_adress" {
  value = module.compute.redis_node_domain
}

# output "redis_address" {
#   value = module.compute.redis_address_endpoint
# }

output "alb_domain" {
  value = module.compute.alb_domain
}