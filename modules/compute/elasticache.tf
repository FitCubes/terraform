resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.vpc_name}-redis-cluster"
  subnet_ids = [for subnet in aws_subnet.elasticache : subnet.id]
}


resource "aws_security_group" "redis" {
  name   = "${var.vpc_name}-redis-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = "6379"
    to_port         = "6379"
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
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
