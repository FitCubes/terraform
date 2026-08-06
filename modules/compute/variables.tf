variable vpc_cidr {
  type = string
  default = "10.0.0.0/16"
}

variable vpc_name {
  type = string
  default = "fitcubes"
}

variable azs {
    type = list(string)
    default = ["en-north-1a", "en-north-1b", "en-north-1c"]
}