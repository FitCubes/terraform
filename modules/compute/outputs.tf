output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_domain" {
  value = aws_db_instance.main.address
}

output "redis_node_domain" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "alb_domain" {
  value = aws_lb.backend.dns_name
}

output "db_instance_identifier" {
  value = aws_db_instance.main.identifier
}
