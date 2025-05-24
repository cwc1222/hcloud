terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

variable "hetzner_ipv4" {
  type = string
  description = "Hetzner IPv4"
}

variable "hetzner_ipv6" {
  type = string
  description = "Hetzner IPv6"
}

variable "subdomains" {
  description = "List of subdomains to create A and AAAA records for"
  type        = list(string)
}

variable "zone_id" {
  type = string
  description = "Cloudflare zone ID"
}

resource "cloudflare_dns_record" "a_record" {
  for_each = toset(var.subdomains)
  zone_id  = var.zone_id
  comment  = "Terraform created A record for ${each.key}"
  content  = var.hetzner_ipv4
  name     = each.key
  type     = "A"
  ttl      = 1
  proxied  = true
}

resource "cloudflare_dns_record" "aaaa_record" {
  for_each = toset(var.subdomains)
  zone_id  = var.zone_id
  comment  = "Terraform created AAAA record for ${each.key}"
  content  = var.hetzner_ipv6
  name     = each.key
  type     = "AAAA"
  ttl      = 1
  proxied  = true
}
