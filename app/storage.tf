resource "random_id" "website" {
  byte_length = 8
}

resource "cloudflare_r2_bucket" "website" {
  account_id = var.cloudflare_account_id
  name       = "${random_id.website.hex}-${replace(var.domain, ".", "-")}"
}
