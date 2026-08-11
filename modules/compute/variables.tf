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

variable "ingress_rules" {
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
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "user_data_path" {
  type = string
}