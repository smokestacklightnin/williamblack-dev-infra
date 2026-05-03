resource "google_service_account" "gha_deploy" {
  account_id   = "gha-deploy"
  display_name = "GitHub Actions site deploy"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "gha_deploy_object_admin" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.gha_deploy.email}"
}

resource "google_storage_bucket_iam_member" "gha_deploy_bucket_reader" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.gha_deploy.email}"
}
