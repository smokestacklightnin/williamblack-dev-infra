resource "random_id" "tf-remote-backend" {
  byte_length = 8
}


resource "google_storage_bucket" "tf-remote-backend" {
  name     = "${random_id.tf-remote-backend.hex}-terraform-remote-backend"
  project  = var.project_id
  location = var.region

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.secure_key.id
  }

  depends_on = [google_kms_crypto_key_iam_binding.gcs_crypto_key_access]
}
