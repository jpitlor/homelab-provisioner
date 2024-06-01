# Homelab Provisioner

Terraform scripts to manage my Homelab

# Prerequisites

1. Authenticate with Google Cloud to provision cloud resources.
The easiest way to do this is by installing [the CLI](https://cloud.google.com/sdk/docs/install).



When creating cloud resources (literal or figurative cloud), 
you need some prerequisites for Terraform to work correctly.

When creating other resources (like provisioning Windows machines 
or laptops), Terraform is not needed, and you can skip this section

(Variable File)

- Google Cloud Platform account
    - Project ID
- Machine running Proxmox
    - URL
    - Account credentials

# Cloud Resources

To create cloud resources, simply run:

```shell
terraform apply
```

TODO: Can this happen in CI instead of manually?

# Provisioning Other Resources

Something something options file?
