data "cloudflare_zone" "main" {
  filter = {
    name = var.domain
  }
}
