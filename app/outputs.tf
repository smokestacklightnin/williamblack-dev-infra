output "website_bucket" {
  value     = cloudflare_r2_bucket.website.name
  sensitive = true
}

output "wif_provider" {
  value     = google_iam_workload_identity_pool_provider.github.name
  sensitive = true
}

output "cloudflare_nameservers" {
  description = "Set these as the nameservers for the domain at Porkbun."
  value       = data.cloudflare_zone.main.name_servers
}
