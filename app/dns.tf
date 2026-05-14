# Apex hostname. This resource creates the apex A/AAAA records server-side
# (no separate cloudflare_dns_record needed) and binds the R2 bucket to the
# hostname for native CF-edge serving.
resource "cloudflare_r2_custom_domain" "apex" {
  account_id  = var.cloudflare_account_id
  zone_id     = data.cloudflare_zone.main.id
  bucket_name = cloudflare_r2_bucket.website.name
  domain      = var.domain
  enabled     = true
  min_tls     = "1.3"
}

# Sinkhole record anchoring www to Cloudflare's proxy so the www->apex
# redirect ruleset (rulesets.tf) actually receives the request. The 100::
# IPv6 address (RFC 6666 Discard Prefix) is ignored at the edge — only the
# proxied flag matters for routing.
resource "cloudflare_dns_record" "www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www.${var.domain}"
  type    = "AAAA"
  content = "100::"
  proxied = true
  ttl     = 1
}
