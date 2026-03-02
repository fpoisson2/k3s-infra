terraform {
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 4" }
    kubernetes  = { source = "hashicorp/kubernetes", version = "~> 2" }
    random      = { source = "hashicorp/random", version = "~> 3" }
  }
}

provider "cloudflare" {
  api_token = var.cf_api_token
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

# --- Tunnel secret ---
resource "random_bytes" "tunnel_secret" {
  length = 32
}

# --- Cloudflare Zero Trust Tunnel ---
resource "cloudflare_zero_trust_tunnel_cloudflared" "k3s" {
  account_id = var.cf_account_id
  name       = "k3s-proxmox"
  secret     = base64encode(random_bytes.tunnel_secret.base64)
}

# --- DNS CNAME vers le tunnel ---
resource "cloudflare_record" "test" {
  zone_id = var.cf_zone_id
  name    = "test"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k3s.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# --- Configuration du tunnel (ingress rules) ---
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "k3s" {
  account_id = var.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.k3s.id

  config {
    ingress_rule {
      hostname = "test.${var.cf_domain}"
      service  = "http://nginx-svc.cloudflare-test.svc.cluster.local:80"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# --- Namespace cloudflare-test (prérequis au secret) ---
resource "kubernetes_namespace" "cloudflare_test" {
  metadata {
    name = "cloudflare-test"
  }
}

# --- Token du tunnel injecté comme secret Kubernetes ---
resource "kubernetes_secret" "tunnel_token" {
  metadata {
    name      = "tunnel-token"
    namespace = kubernetes_namespace.cloudflare_test.metadata[0].name
  }

  data = {
    token = cloudflare_zero_trust_tunnel_cloudflared.k3s.tunnel_token
  }

  depends_on = [kubernetes_namespace.cloudflare_test]
}
