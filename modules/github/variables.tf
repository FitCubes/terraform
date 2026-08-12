variable "frontend_repo_name" {
  type    = string
  default = "frontend"
}

variable "backend_repo_name" {
  type    = string
  default = "backend"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_access_key_secret" {
  type = string
  sensitive = true
}

variable "aws_region" {
  type = string
}

variable "frontend_s3_bucket" {
  type = string
}

variable "asg_resresh_access_key" {
  type      = string
  sensitive = true
}

variable "asg_refresh_access_key_secret" {
  type      = string
  sensitive = true
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
  type = string
  sensitive = true
}