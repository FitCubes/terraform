variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "backend_bucket_name" {
  type    = string
  default = "backendbucketfircubes"
}


variable "frontend_bucket_name" {
  type    = string
  default = "frontendbucketfircubes"
}

variable "project_name" {
  type    = string
  default = "fitcubes"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "fitcubes"
}

variable "ami" {
  type    = string
  default = "ami-0e91d8cb1f8959277"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/ec2.pub"
}

variable "user_data_path" {
  type    = string
  default = "./user-data.sh"
}

variable "subnets_public_cidrs" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "0" = { cidr = "10.0.1.0/24", az = "eu-north-1a" }
    "1" = { cidr = "10.0.2.0/24", az = "eu-north-1b" }
    "3" = { cidr = "10.0.6.0/24", az = "eu-north-1c" }
  }
}

variable "subnets_database_cidrs" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "0" = { cidr = "10.0.3.0/24", az = "eu-north-1a" }
    "2" = { cidr = "10.0.4.0/24", az = "eu-north-1c" }
  }
}

variable "elasticache_cidrs" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "2" = { cidr = "10.0.5.0/24", az = "eu-north-1c" }
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}


variable "postgres_password" {
  type      = string
  sensitive = true
}


variable "postgres_username" {
  type      = string
  sensitive = true
}

variable "postgres_db_name" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "github_owner" {
  type = string
}

variable "dockerhub_username" {
  type      = string
  sensitive = true
}


variable "dockerhub_token" {
  type      = string
  sensitive = true
}

variable "repository_name" {
  type      = string
  sensitive = true
}
variable "frontend_domain" {
  type = string
}

variable "cloudflare_token" {
  type      = string
  sensitive = true
}

variable "backend_domain" {
  type = string
}

variable "cloudflare_zone_id" {
  type      = string
  sensitive = true
}