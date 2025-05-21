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

data "cloudflare_zone" "domain" {
  filter = {
    name = var.domain
  }
}

data "hcloud_primary_ip" "primary_ip_ipv4" {
  name = "${var.domain}.ipv4"
}

data "hcloud_primary_ip" "primary_ip_ipv6" {
  name = "${var.domain}.ipv6"
}

variable "domain" {
  type = string
  description = "Domain name"
}

variable "subdomains" {
  description = "List of subdomains to create A and AAAA records for"
  type        = list(string)
}

variable "dns_ttl" {
  type = number
  description = "DNS TTL"
  default = 3600
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
  zone_id  = data.cloudflare_zone.domain.id
  comment  = "Terraform created A record for ${each.key}"
  content  = data.hcloud_primary_ip.primary_ip_ipv4.ip_address
  name     = each.key
  type     = "A"
  ttl      = var.dns_ttl
  proxied  = true
}

resource "cloudflare_dns_record" "aaaa_record" {
  for_each = toset(var.subdomains)
  zone_id  = data.cloudflare_zone.domain.id
  comment  = "Terraform created AAAA record for ${each.key}"
  content  = data.hcloud_primary_ip.primary_ip_ipv6.ip_address
  name     = each.key
  type     = "AAAA"
  ttl      = var.dns_ttl
  proxied  = true
}

// Polaris Mail Server Configuration
// REF: https://wiki.polarismail.com/display/Support/Autodiscover
resource "cloudflare_dns_record" "polarismail_autodiscover" {
  zone_id = data.cloudflare_zone.domain.id
  comment = "Terraform created A record for Polaris Mail Autodiscover"
  content = "69.28.212.195"
  name = "autodiscover"
  type = "A"
  ttl = var.dns_ttl
  proxied = false
}

// REF: https://wiki.polarismail.com/display/Support/DNS+Configuration
resource "cloudflare_dns_record" "polarismail_webmail" {
  zone_id = data.cloudflare_zone.domain.id
  comment = "Terraform created CNAME record for Polaris Mail Webmail"
  content = "webredirect.emailarray.com"
  name = "webmail"
  type = "CNAME"
  ttl = var.dns_ttl
  proxied = true
}

resource "cloudflare_dns_record" "polarismail_mx1" {
  zone_id = data.cloudflare_zone.domain.id
  comment = "Terraform created MX record for Polaris Mail"
  content = "mx.emailarray.com"
  name = "@"
  type = "MX"
  ttl = var.dns_ttl
  priority = 5
}

resource "cloudflare_dns_record" "polarismail_mx2" {
  zone_id = data.cloudflare_zone.domain.id
  comment = "Terraform created MX record for Polaris Mail"
  content = "mx2.emailarray.com"
  name = "@"
  type = "MX"
  ttl = var.dns_ttl
  priority = 10
}

resource "cloudflare_dns_record" "polarismail_spf" {
  zone_id = data.cloudflare_zone.domain.id
  comment = "Terraform created SPF record for Polaris Mail"
  content = "v=spf1 include:emailarray.com -all"
  name = "@"
  type = "TXT"
  ttl = 1800 // 30 minutes
}

resource "cloudflare_dns_record" "polarismail_dkim" {
  zone_id = data.cloudflare_zone.domain.id
  comment = "Terraform created DKIM record for Polaris Mail"
  content = var.dkim_pubkey
  name = var.dkim_selector
  type = "TXT"
  ttl = 1 // automatic
}