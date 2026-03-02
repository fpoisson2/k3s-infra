variable "cf_api_token" {
  description = "Cloudflare API token (Zero Trust + DNS Edit permissions)"
  type        = string
  sensitive   = true
}

variable "cf_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cf_zone_id" {
  description = "Cloudflare Zone ID pour ton domaine"
  type        = string
}

variable "cf_domain" {
  description = "Domaine principal (ex: ve2fpd.com)"
  type        = string
}
