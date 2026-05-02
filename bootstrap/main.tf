data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "local_file" "tf-remote-backend" {
  file_permission = "0644"
  filename        = "${path.module}/backend.tf"

  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${google_storage_bucket.tf-remote-backend.name}"
      prefix    = "state-bucket"
    }
  }
  EOT
}
