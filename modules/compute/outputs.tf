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


output "alb_domain" {
  value = aws_lb.backend.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.ec2_asg.name
}

output "db_instance_identifier" {
  value = aws_db_instance.main.identifier
}


output "target_group_suffix" {
  value = aws_lb_target_group.backend.arn_suffix
}

output "alb_suffix" {
  value = aws_lb.backend.arn_suffix
}

output "docker_sha_ssm_name" {
  value = aws_ssm_parameter.docker_sha.name
}

output "docker_sha_ssm_arn" {
  value = aws_ssm_parameter.docker_sha.arn
}
