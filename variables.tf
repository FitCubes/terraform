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

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}