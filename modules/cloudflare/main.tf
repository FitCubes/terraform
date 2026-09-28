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

data "cloudflare_api_token_permission_groups_list" "cache_purge" {
  name = "Cache Purge"
}

resource "cloudflare_api_token" "cache_purge" {
  name = "github-actions-cache-purge"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        {
          id = data.cloudflare_api_token_permission_groups_list.cache_purge.result[0].id
        }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
      })
    }
  ]
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

resource "cloudflare_dns_record" "ses_dkim" {
  count = 3
  zone_id = var.cloudflare_zone_id

  name = "${var.ses_dkim_tokens[count.index]}._domainkey"
  content = "${var.ses_dkim_tokens[count.index]}.dkim.amazonses.com"
  type = "CNAME"
  proxied = false
  ttl = 1
}


resource "cloudflare_dns_record" "dmarc_ses" {
  zone_id = var.cloudflare_zone_id

  name = "_dmarc"
  content = "\"v=DMARC1; p=none;\""
  type = "TXT"
  ttl = 1
}


resource "cloudflare_dns_record" "ses_mx" {
  zone_id = var.cloudflare_zone_id

  name = var.ses_email_subdomain
  content = "feedback-smtp.${var.region}.amazonses.com"
  ttl = 1
  priority = 10
  type = "MX"
}

resource "cloudflare_dns_record" "spf_ses_from" {
  zone_id = var.cloudflare_zone_id

  name = var.ses_email_subdomain
  content = "\"v=spf1 include:amazonses.com ~all\""
  type = "TXT"
  ttl = 1
}
