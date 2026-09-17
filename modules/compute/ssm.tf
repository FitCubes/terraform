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

resource "aws_ssm_parameter" "datasource_url" {
  name  = "/${var.vpc_name}/backend/datasource_url"
  type  = "SecureString"
  value = "jdbc:postgresql://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}
