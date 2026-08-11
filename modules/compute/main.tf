resource "aws_db_subnet_group" "postgres" {
  name       = "${var.vpc_name}-subnet-group"
  subnet_ids = [for subnet in aws_subnet.database : subnet.id]
}

resource "aws_db_instance" "main" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = var.postgres_version
  instance_class         = var.postgres_instance
  username               = var.postgres_username
  password               = var.postgres_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  db_name                = var.postgres_db_name
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.vpc_name}-redis-cluster"
  subnet_ids = [for subnet in aws_subnet.elasticache : subnet.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id         = "${var.vpc_name}-redis-cluster"
  node_type          = var.node_type_redis
  engine             = "redis"
  num_cache_nodes    = 1
  engine_version     = var.engine_version_redis
  port               = "6379"
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
}


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