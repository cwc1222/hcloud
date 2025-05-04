# hcloud
VPS management on Hetzner Cloud

## Quick Start

```bash
export PG_CONN_STR=postgres://user:pass@db.example.com/terraform
terraform init
```

## How to find available images

1. Use curl

```bash
curl \
	-H "Authorization: Bearer $H_API_TOKEN" \
	"https://api.hetzner.cloud/v1/images"

curl \
	-H "Authorization: Bearer $H_API_TOKEN" \
	"https://api.hetzner.cloud/v1/images/$ID"
```

2. Use [hcloud cli](https://github.com/hetznercloud/cli)

```bash
hcloud context create <ur-project-name>
hcloud image list -t system -a x86
```

## Reference

- [developer.hashicorp.com/terraform/intro](https://developer.hashicorp.com/terraform/intro)
- [docs.hetzner.com/cloud](https://docs.hetzner.com/cloud)
- [registry.terraform.io/providers/hetznercloud/hcloud/latest/docs](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [developer.hashicorp.com/terraform/tutorials/provision/cloud-init](https://developer.hashicorp.com/terraform/tutorials/provision/cloud-init)
- [dennmart.com/articles/get-started-with-hetzner-cloud-and-terraform-for-easy-deployments/](https://dennmart.com/articles/get-started-with-hetzner-cloud-and-terraform-for-easy-deployments/)
- [medium.com/@orestovyevhen/set-up-infrastructure-in-hetzner-cloud-using-terraform-ce85491e92d](https://medium.com/@orestovyevhen/set-up-infrastructure-in-hetzner-cloud-using-terraform-ce85491e92d)
- [community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster](https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster)
- [scottspence.com/posts/setting-up-my-vps-on-hetzner](https://scottspence.com/posts/setting-up-my-vps-on-hetzner)
- [github.com/hetznercloud/cli](https://github.com/hetznercloud/cli)