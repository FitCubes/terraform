# output "eip" {
#   value = aws_eip.main.public_ip
# }
# output "instance_domain" {
#   value = aws_instance.web.public_dns
# }

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_domain" {
  value = aws_db_instance.main.address
}

output "redis_domain" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}