
terraform {
  required_version = ">= 1.5.0"

 required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "k3s_kubeconfig" {
  name           = "/k3s/kubeconfig"
  with_decryption = true
  depends_on = [ module.k3s_cluster ]
}
locals {
  kubeconfig_fixed = replace(
    data.aws_ssm_parameter.k3s_kubeconfig.value,
    "127.0.0.1",
    local.master_ip
  )
}
resource "local_file" "k3s_kubeconfig_file" {
  content  = local.kubeconfig_fixed
  filename = "${path.module}/k3s.yaml"
}


# Kubernetes provider uses the file
provider "kubernetes" {
  config_path = local_file.k3s_kubeconfig_file.filename
}
provider "kubectl" {
  config_path = local_file.k3s_kubeconfig_file.filename
}

# Helm provider uses the same file
provider "helm" {
 kubernetes  {
   config_path = local_file.k3s_kubeconfig_file.filename
 }
}