# 🚀 K3s Cluster on AWS using Terraform

This project provisions a fully functional **K3s Kubernetes cluster** on
AWS using Terraform. It follows a modular structure and includes VPC,
IAM, EC2 nodes, and secure access using AWS Systems Manager (SSM).

------------------------------------------------------------------------

# 📐 Architecture Overview

The infrastructure consists of:

-   Custom VPC
-   Public and Private Subnets
-   IAM Role & Instance Profile for EC2
-   Security Groups
-   K3s Master Node (Public Subnet)
-   Configurable Worker Nodes (Private Subnet)
-   Secure SSM-based access (No SSH required)

------------------------------------------------------------------------

## Project Structure

```bash
.
├── config
│   └── dev.tfvars
├── main.tf
├── modules
│   ├── iam
│   │   ├── main.tf
│   │   ├── output.tf
│   │   └── variable.tf
│   ├── nodes
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── userdata
│   │   │   ├── master.sh
│   │   │   └── worker.sh
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── provider.tf
├── README.md
└── variables.tf
```


------------------------------------------------------------------------

# 🧩 Root Variables

## VPC Configuration

``` hcl
variable "vpc" {
  description = "Configurations for VPC"
  type = object({
    vpc_name                = string
    vpc_cidr                = string
    public_subnet_cidrs     = list(string)
    private_subnet_cidrs    = list(string)
    cidr_block              = string
    domain                  = string
    map_public_ip_on_launch = bool
    dns_host_name           = bool
    enable_dns_support      = bool
  })
}
```

## Base Tags

``` hcl
variable "base_tags" {
  type = map(string)
}
```
## AWS Region

``` hcl
variable "aws_region" {
  type = string
}
```

## Cluster Configuration

``` hcl
variable "cluster_config" {
  description = "Complete configuration for K3s cluster infrastructure"

  type = object({
    k3s_sg_name               = string
    k3s_master_instance_type  = string
    k3s_master_name           = string
    k3s_worker_instance_type  = string
    worker_ingress_ports      = list(number)
    master_ingress_ports      = list(number)
    k3s_worker_name_prefix    = string
    worker_count              = number
  })
}
```

## IAM Configuration

``` hcl
variable "iam" {
  description = "IAM configuration"
  type = object({
    node_role_name    = string
    node_profile_name = string
  })
}
```

------------------------------------------------------------------------

# 📦 Root Module Calls

## VPC Module

``` hcl
module "vpc" {
  source                  = "./modules/vpc"
  vpc_name                = var.vpc.vpc_name
  vpc_cidr                = var.vpc.vpc_cidr
  cidr_block              = var.vpc.cidr_block
  public_subnet_cidrs     = var.vpc.public_subnet_cidrs
  private_subnet_cidrs    = var.vpc.private_subnet_cidrs
  domain                  = var.vpc.domain
  map_public_ip_on_launch = var.vpc.map_public_ip_on_launch
  enable_dns_support      = var.vpc.enable_dns_support
  dns_host_name           = var.vpc.dns_host_name
  tags                    = var.base_tags
}
```

## IAM Module

``` hcl
module "iam" {
  source            = "./modules/iam"
  node_role_name    = var.iam.node_role_name
  node_profile_name = var.iam.node_profile_name
}
```

## K3s Cluster Module

``` hcl
module "k3s_cluster" {
  source = "./modules/nodes"

  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = module.vpc.vpc_cidr
  public_subnet_id     = module.vpc.public_subnet_ids[0]
  private_subnet_id    = module.vpc.private_subnet_ids[0]
  iam_instance_profile = module.iam.node_iam_instance_profile
  ami_id               = data.aws_ami.ubuntu22.id

  k3s_sg_name = var.cluster_config.k3s_sg_name

  k3s_master_instance_type = var.cluster_config.k3s_master_instance_type
  k3s_master_name          = var.cluster_config.k3s_master_name

  k3s_worker_instance_type = var.cluster_config.k3s_worker_instance_type
  k3s_worker_name_prefix   = var.cluster_config.k3s_worker_name_prefix
  worker_count             = var.cluster_config.worker_count
  master_ingress_ports     = var.cluster_config.master_ingress_ports
  worker_ingress_ports     = var.cluster_config.worker_ingress_ports
}
```

------------------------------------------------------------------------

# 🔐 Secure Access (SSM Based)

This setup allows secure access to the K3s master node using AWS Systems
Manager:

-   No SSH port (22) exposure required
-   No Bastion Host required
-   IAM-based access control
-   Encrypted session management

Connect:

``` bash
aws ssm start-session --target <instance-id>  --region your-region

```

Verify cluster:

``` bash
sudo kubectl get nodes
sudo kubectl get pods -A
```

------------------------------------------------------------------------

# 🚀 Deployment

``` bash
terraform init
terraform plan -var-file="config/dev.tfvars"
terraform apply -var-file="config/dev.tfvars"
```

------------------------------------------------------------------------

# ✅ What This Setup Provides

-   Modular Terraform design
-   Secure SSM-only access
-   Scalable worker node configuration
-   Clean separation of infrastructure layers
-   Production-ready base structure