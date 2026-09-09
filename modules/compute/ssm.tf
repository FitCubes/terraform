resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.vpc_name}/database/password"
  description = "Database Password"
  type        = "SecureString"
  value       = aws_db_instance.main.password
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.vpc_name}/database/username"
  description = "Database Username"
  type        = "SecureString"
  value       = aws_db_instance.main.username
}

resource "aws_ssm_parameter" "db_address" {
  name        = "/${var.vpc_name}/database/address"
  description = "Database Address"
  type        = "SecureString"
  value       = aws_db_instance.main.address
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.vpc_name}/database/name"
  description = "Database Name"
  type        = "SecureString"
  value       = aws_db_instance.main.db_name
}

resource "aws_ssm_parameter" "redis_address" {
  name        = "/${var.vpc_name}/redis/address"
  description = "Redis Address"
  type        = "SecureString"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.vpc_name}/backend/jwt_secret"
  description = "Redis Address"
  type        = "SecureString"
  value       = var.jwt_secret
}

resource "aws_ssm_parameter" "frontend_url" {
  name  = "/${var.vpc_name}/backend/frontend_url"
  type  = "SecureString"
  value = "https://${var.frontend_domain}"
}

resource "aws_ssm_parameter" "docker_sha" {
  name  = "/${var.vpc_name}/backend/docker_sha"
  type  = "String"
  value = "latest"
  lifecycle {
    ignore_changes = [value]
  }
}
