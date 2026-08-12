resource "cloudflare_dns_record" "frontend_cname" {
  ttl     = "1"
  type    = "CNAME"
  name    = var.frontend_record_name
  zone_id = var.cloudflare_zone_id
  content = var.frontent_bucket_domain
  proxied = true
}

resource "cloudflare_dns_record" "alb_cname" {
  ttl     = "1"
  type    = "CNAME"
  name    = var.backend_record_name
  zone_id = var.cloudflare_zone_id
  content = var.alb_domain
  proxied = true
}

resource "cloudflare_ruleset" "bypass_caching" {
  zone_id = var.cloudflare_zone_id
  name    = "Cache skip"
  phase   = "http_request_cache_settings"
  kind    = "zone"
  rules = [{
    expression  = "(http.host eq \"${var.alb_domain}\")"
    description = "Never cache API/backend responses"
    action      = "set_cache_settings"
    action_parameters = {
      cache = false
    }
  }]
}