data "cloudflare_zone" "main" {
  name = var.domain
}

resource "cloudflare_record" "apex" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  type    = "AAAA"
  content = "100::"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www"
  type    = "AAAA"
  content = "100::"
  proxied = true
  ttl     = 1
}

resource "cloudflare_workers_script" "proxy" {
  account_id = var.cloudflare_account_id
  name       = "${replace(var.domain, ".", "-")}-proxy"
  content    = file("${path.module}/worker/proxy.js")
  module     = true

  plain_text_binding {
    name = "BUCKET"
    text = google_storage_bucket.website.name
  }
}

resource "cloudflare_workers_route" "apex" {
  zone_id     = data.cloudflare_zone.main.id
  pattern     = "${var.domain}/*"
  script_name = cloudflare_workers_script.proxy.name
}

resource "cloudflare_workers_route" "www" {
  zone_id     = data.cloudflare_zone.main.id
  pattern     = "www.${var.domain}/*"
  script_name = cloudflare_workers_script.proxy.name
}
