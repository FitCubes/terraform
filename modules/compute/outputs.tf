output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_domain" {
  value = aws_db_instance.main.address
}

output "redis_node_domain" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "asg_arn" {
  value = aws_autoscaling_group.ec2_asg.arn
}

# output "redis_address_endpoint" {
#   value = aws_elasticache_cluster.redis.configuration_endpoint
# }

# output "alb_domain" {
#   value = aws_lb.backend.dns_name
# }