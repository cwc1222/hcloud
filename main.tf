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
  api_token = var.cloudflare_api_token
}

variable "cloudflare_api_token" {
  sensitive = true
  type = string
  description = "Cloudflare API Token"
}

variable "hcloud_token" {
  sensitive = true
  type = string
  description = "Hetzner Cloud API Token"
}

variable "ssh_pubkey" {
  type = string
  description = "SSH Public Key"
}

variable "ssh_user" {
  type = string
  description = "SSH User"
}

variable "cloud_init_fqdn" {
  type = string
  description = "Cloud-Init FQDN"
}

variable "cloud_init_hostname" {
  type = string
  description = "Cloud-Init Hostname"
}

variable "cloud_init_locale" {
  type = string
  default = "en_US.UTF-8"
  description = "Cloud-Init Locale"
}

variable "cloud_init_timezone" {
  type = string
  default = "Etc/UTC"
  description = "Cloud-Init Timezone"
}

variable "server_name" {
  type = string
  description = "Server Name"
}

variable "server_type" {
  # hcloud server-type list
  type = string
  default = "cx22"
  description = "Server Type, default to be cx22 shared intel 2vCPU 4GB RAM"
}

variable "image" {
  # https://docs.hetzner.cloud/#images
  # https://www.reddit.com/r/hetzner/comments/12jrh42/terraform_with_hetzner/
  # hcloud image list -t system -a x86
  type = string
  default = "debian-12"
  description = "Image"
}

variable "location_zone" {
  type = string
  default = "eu-central"
  description = "Location Zone"
}

variable "datacenter" {
  # hcloud datacenter list
  type = string
  default = "fsn1-dc14"
  description = "Datacenter"
}

variable "labels" {
  type = map(string)
  description = "Labels"
}

variable "firewall_name" {
  type = string
  description = "Firewall Name"
}

variable "network_name" {
  type = string
  description = "Network Name"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_firewall" "firewall" {
  name = var.firewall_name

  rule {
    description = "Allow SSH traffic"
    direction = "in"
    protocol = "tcp"
    port = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow HTTP traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "Allow HTTPS traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_network" "network" {
  name = var.network_name
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "subnet" {
  network_id = hcloud_network.network.id
  type = "cloud"
  network_zone = var.location_zone
  ip_range = "10.0.1.0/24"
}

resource "hcloud_primary_ip" "primary_ip_ipv4" {
  name = "chenantunez.com.ipv4"
  datacenter = var.datacenter
  type = "ipv4"
  assignee_type = "server"
  auto_delete = true
}

resource "hcloud_primary_ip" "primary_ip_ipv6" {
  name = "chenantunez.com.ipv6"
  datacenter = var.datacenter
  type = "ipv6"
  assignee_type = "server"
  auto_delete = true
}

resource "hcloud_server" "server" {
  name = var.server_name
  image = var.image
  server_type = var.server_type
  datacenter = var.datacenter
  firewall_ids = [hcloud_firewall.firewall.id]
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    ssh_pubkey = var.ssh_pubkey
    ssh_user = var.ssh_user
    fqdn = var.cloud_init_fqdn
    hostname = var.cloud_init_hostname
    locale = var.cloud_init_locale
    timezone = var.cloud_init_timezone
  })

  labels = var.labels

  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.primary_ip_ipv4.id
    ipv6_enabled = true
    ipv6 = hcloud_primary_ip.primary_ip_ipv6.id
  }

  network {
    network_id = hcloud_network.network.id
    ip = "10.0.1.1"
  }

  depends_on = [ hcloud_network_subnet.subnet ]
}

output "server_location" {
  description = "Server Location and Zone"
  value = "zone: ${var.location_zone}, datacenter: ${var.datacenter}"
}

output "server_ipv4" {
  description = "Server IPv4"
  value = hcloud_primary_ip.primary_ip_ipv4.ip_address
}

output "server_ipv6" {
  description = "Server IPv6"
  value = hcloud_primary_ip.primary_ip_ipv6.ip_address
}

output "server_ssh_user" {
  description = "Server SSH User"
  value = var.ssh_user
}
