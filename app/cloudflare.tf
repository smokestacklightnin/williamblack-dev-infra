data "cloudflare_zone" "main" {
  filter = {
    name = var.domain
  }
}

resource "cloudflare_dns_record" "apex" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.domain
  type    = "AAAA"
  content = "100::"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www.${var.domain}"
  type    = "AAAA"
  content = "100::"
  proxied = true
  ttl     = 1
}

resource "cloudflare_workers_script" "proxy" {
  account_id  = var.cloudflare_account_id
  script_name = "${replace(var.domain, ".", "-")}-proxy"
  content     = file("${path.module}/worker/proxy.js")
  main_module = "proxy.js"

  bindings = [{
    name = "BUCKET"
    type = "plain_text"
    text = google_storage_bucket.website.name
  }]
}

resource "cloudflare_workers_route" "apex" {
  zone_id = data.cloudflare_zone.main.id
  pattern = "${var.domain}/*"
  script  = cloudflare_workers_script.proxy.id
}

resource "cloudflare_workers_route" "www" {
  zone_id = data.cloudflare_zone.main.id
  pattern = "www.${var.domain}/*"
  script  = cloudflare_workers_script.proxy.id
}
