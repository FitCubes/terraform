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

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.backend.family
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.backend.name
}

output "ecs_service_name" {
  value = aws_ecs_service.backend.name
}

output "ecs_service_arn" {
  value = aws_ecs_service.backend.arn
}

output "esc_task_execution_role" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
