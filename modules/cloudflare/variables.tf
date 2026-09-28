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
}

variable "ses_dkim_tokens" {
  type = list(string)
}

variable "ses_email_subdomain" {
  type = string
  default = "no-reply"
}

variable "region" {
  type = string
}
