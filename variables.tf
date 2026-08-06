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