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
  type = map(string)
}

variable "subnets_database_cidrs" {
  type = map(string)
}

variable "elasticache_cidrs" {
  type = map(string)
}

variable "ingress_rules_backend" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
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