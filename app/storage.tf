resource "random_id" "website" {
  byte_length = 8
}

resource "google_storage_bucket" "website" {
  name     = "${random_id.website.hex}-${replace(var.domain, ".", "-")}"
  project  = var.project_id
  location = var.region

  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "website_public_read" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "random_id" "r2_website" {
  byte_length = 8
}

resource "cloudflare_r2_bucket" "website" {
  account_id = var.cloudflare_account_id
  name       = "${random_id.r2_website.hex}-${replace(var.domain, ".", "-")}"
}
