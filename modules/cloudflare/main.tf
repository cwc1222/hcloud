terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.50"
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

variable "zone_id" {
  type = string
  description = "Zone ID"
}

variable "subdomains" {
  description = "List of subdomains to create A and AAAA records for"
  type        = list(string)
}

variable "dkim_selector" {
  type = string
  description = "DKIM selector"
}

variable "dkim_pubkey" {
  type = string
  description = "DKIM public key"
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

// Polaris Mail Server Configuration
// REF: https://wiki.polarismail.com/display/Support/Autodiscover
resource "cloudflare_dns_record" "polarismail_autodiscover" {
  zone_id = var.zone_id
  comment = "Terraform created A record for Polaris Mail Autodiscover"
  content = "69.28.212.195"
  name = "autodiscover"
  type = "A"
  ttl = 1
  proxied = false
}

// REF: https://wiki.polarismail.com/display/Support/DNS+Configuration
resource "cloudflare_dns_record" "polarismail_webmail" {
  zone_id = var.zone_id
  comment = "Terraform created CNAME record for Polaris Mail Webmail"
  content = "webredirect.emailarray.com"
  name = "webmail"
  type = "CNAME"
  ttl = 1
  proxied = true
}

resource "cloudflare_dns_record" "polarismail_mx1" {
  zone_id = var.zone_id
  comment = "Terraform created MX record for Polaris Mail"
  content = "mx.emailarray.com"
  name = "@"
  type = "MX"
  ttl = 3600 // 1 hour
  priority = 5
}

resource "cloudflare_dns_record" "polarismail_mx2" {
  zone_id = var.zone_id
  comment = "Terraform created MX record for Polaris Mail"
  content = "mx2.emailarray.com"
  name = "@"
  type = "MX"
  ttl = 3600 // 1 hour
  priority = 10
}

resource "cloudflare_dns_record" "polarismail_spf" {
  zone_id = var.zone_id
  comment = "Terraform created SPF record for Polaris Mail"
  content = "\"v=spf1 include:emailarray.com -all\""
  name = "@"
  type = "TXT"
  ttl = 1800 // 30 minutes
}

resource "cloudflare_dns_record" "polarismail_dkim" {
  zone_id = var.zone_id
  comment = "Terraform created DKIM record for Polaris Mail"
  content = "\"${var.dkim_pubkey}\""
  name = var.dkim_selector
  type = "TXT"
  ttl = 1 // automatic
}
