terraform {
  backend "gcs" {
    # bucket is supplied via TF_CLI_ARGS_init in infra/.envrc.
    prefix = "app-infra"
  }
}
