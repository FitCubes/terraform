output "cache_purge_token" {
  value     = cloudflare_api_token.cache_purge.value
  sensitive = true
}
