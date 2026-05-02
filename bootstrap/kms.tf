resource "google_kms_key_ring" "secure_key_ring" {
  name     = "${random_id.tf-remote-backend.hex}-secure-storage-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "secure_key" {
  name            = "${random_id.tf-remote-backend.hex}-bucket-key"
  key_ring        = google_kms_key_ring.secure_key_ring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "gcs_crypto_key_access" {
  crypto_key_id = google_kms_crypto_key.secure_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  ]
}
