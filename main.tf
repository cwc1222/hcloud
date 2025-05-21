terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.50"
    }

    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  backend "s3" {
    bucket = "tf-state"
    key = "terraform.tfstate"
    region = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token_dns
}

provider "hcloud" {
  token = var.hcloud_token
}

module "hetzner" {
  source = "./modules/hetzner"

  ssh_pubkey = var.ssh_pubkey
  ssh_user = var.ssh_user
  cloud_init_fqdn = var.cloud_init_fqdn
  cloud_init_hostname = var.cloud_init_hostname
  cloud_init_locale = var.cloud_init_locale
  cloud_init_timezone = var.cloud_init_timezone
  server_name = var.server_name
  server_type = var.server_type
  image = var.image
  location_zone = var.location_zone
  datacenter = var.datacenter
  labels = var.labels
  firewall_name = var.firewall_name
  network_name = var.network_name
}

module "cloudflare" {
  source = "./modules/cloudflare"

  domain = var.domain
  subdomains = ["catopia", "vw"]
  dns_ttl = var.dns_ttl
  dkim_selector = var.dkim_selector
  dkim_pubkey = var.dkim_pubkey
  depends_on = [ module.hetzner ]
}
