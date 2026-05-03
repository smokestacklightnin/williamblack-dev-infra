variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "github_owner" {
  type    = string
  default = "smokestacklightnin"
}

variable "site_repo" {
  type    = string
  default = "williamblack-dev"
}

variable "infra_repo" {
  type    = string
  default = "williamblack-dev-infra"
}

variable "domain" {
  type    = string
  default = "williamblack.dev"
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
