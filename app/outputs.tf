output "website_bucket" {
  value = google_storage_bucket.website.name
}

output "gha_deploy_sa" {
  value = google_service_account.gha_deploy.email
}

output "wif_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "cloudflare_nameservers" {
  description = "Set these as the nameservers for the domain at Porkbun."
  value       = data.cloudflare_zone.main.name_servers
}
