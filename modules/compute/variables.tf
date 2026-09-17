variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnets_public_cidrs" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "subnets_database_cidrs" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "elasticache_cidrs" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "postgres_version" {
  type    = string
  default = "18.3"
}

variable "postgres_instance" {
  type    = string
  default = "db.t4g.micro"
}

variable "postgres_username" {
  type = string
}

variable "postgres_password" {
  type = string
}

variable "postgres_db_name" {
  type = string
}

variable "node_type_redis" {
  type    = string
  default = "cache.t4g.micro"
}

variable "engine_version_redis" {
  type    = string
  default = "7.1"
}

variable "jwt_secret" {
  type = string
}

variable "frontend_domain" {
  type = string
}

variable "lambda_memody_size" {
  type    = number
  default = 128
}

variable "log_group_lamdba_smoke" {
  type = string
}

variable "log_group_name_ecs" {
  type    = string
  default = "fitcubes/ecs/backend"
}

variable "repository_name" {
  type      = string
  sensitive = true
}
