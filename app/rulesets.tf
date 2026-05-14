resource "cloudflare_ruleset" "transform_index_html" {
  zone_id = data.cloudflare_zone.main.id
  name    = "Append index.html to directory paths"
  kind    = "zone"
  phase   = "http_request_transform"

  rules = [{
    description = "Append index.html when path ends with /"
    expression  = "ends_with(http.request.uri.path, \"/\")"
    action      = "rewrite"
    action_parameters = {
      uri = {
        path = {
          expression = "concat(http.request.uri.path, \"index.html\")"
        }
      }
    }
  }]
}

resource "cloudflare_ruleset" "redirect_www_to_apex" {
  zone_id = data.cloudflare_zone.main.id
  name    = "Redirect www to apex"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    description = "301 www to apex"
    expression  = "http.host eq \"www.${var.domain}\""
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code           = 301
        preserve_query_string = true
        target_url = {
          expression = "concat(\"https://${var.domain}\", http.request.uri.path)"
        }
      }
    }
  }]
}
