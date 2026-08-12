variable "frontent_bucket_domain" {
  type = string
}

variable "cloudflare_zone_id" {
  type      = string
  sensitive = true
}

variable "frontend_record_name" {
  type    = string
  default = "@"
}

variable "alb_domain" {
  type = string
}

variable "backend_record_name" {
  type    = string
  default = "alb"
}
