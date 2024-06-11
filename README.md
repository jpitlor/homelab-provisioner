# Homelab Provisioner

Terraform scripts to manage my Homelab

# Prerequisites

- [Google Cloud Platform](https://console.cloud.google.com/) account
  - The name of the project you want to create in GCP
- Machine running [Proxmox](https://www.proxmox.com/en/downloads)
  - URL
  - Account credentials
- [OpenTofu](https://opentofu.org/docs/intro/install/) installed

# Bootstrap

First, authenticate with Google Cloud. The easiest way to do this is
by installing [the CLI](https://cloud.google.com/sdk/docs/install).

Next, go into the `bootstrap-1-project` folder, and prepare the variable
files.

```shell
cd bootstrap-1-project
cp .env.example .env
cp terraform.tfvars.example terraform.tfvars
```

Go into the newly created `.env` and `terraform.tfvars` and change the 
parts that say `CHANGEME`. Then, run OpenTofu. This should create the 
project in GCP.

```shell
source .env
tofu init
tofu apply
```

Now, you need to move on to the second half of bootstrapping, creating
the bucket that will ultimately be used for the main OpenTofu state file

```shell
cd ../bootstrap-2-project
tofu init
tofu apply
cd ..
```

# Usage

First, you'll need to fill in the variables

```shell
cp terraform.tfvars.example terraform.tfvars
```

Go into the newly created `terraform.tfvars` and update all the
values that say `CHANGEME`. Then, simply run:

```shell
source .env
tofu init
tofu apply
```

TODO: Make this happen automatically in Gitea in the nuc

# Provisioning Other Resources

TODO: Add options files (or otherwise) to provision resources that
aren't created in Terraform
