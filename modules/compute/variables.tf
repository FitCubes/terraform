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

variable "ami" {
  type    = string
  default = "ami-01ddfb2eb6deb865c"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_key_path" {
  type = string
}

variable "user_data_path" {
  type = string
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

