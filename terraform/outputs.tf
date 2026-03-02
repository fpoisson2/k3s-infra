output "tunnel_id" {
  description = "ID du tunnel Cloudflare"
  value       = cloudflare_zero_trust_tunnel_cloudflared.k3s.id
}

output "tunnel_name" {
  description = "Nom du tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.k3s.name
}

output "dns_record" {
  description = "CNAME créé dans Cloudflare DNS"
  value       = "${cloudflare_record.test.name}.${var.cf_domain}"
}
