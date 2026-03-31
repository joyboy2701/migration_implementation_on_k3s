data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"] 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
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
  tags                    = merge(var.base_tags, var.vpc.tags)
}
module "k3s_cluster" {
  source = "./modules/nodes"

  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = module.vpc.vpc_cidr
  public_subnet_id            = module.vpc.public_subnet_ids[0]
  private_subnet_id           = module.vpc.private_subnet_ids[0]
  iam_instance_profile_master = module.iam.node_iam_instance_profile_master
  iam_instance_profile_worker = module.iam.node_iam_instance_profile_worker
  ami_id                      = data.aws_ami.ubuntu22.id
  region                      = var.aws_region
  k3s_sg_name                 = var.cluster_config.k3s_sg_name

  k3s_master_instance_type = var.cluster_config.k3s_master_instance_type
  k3s_master_name          = var.cluster_config.k3s_master_name

  k3s_worker_instance_type = var.cluster_config.k3s_worker_instance_type
  k3s_worker_name_prefix   = var.cluster_config.k3s_worker_name_prefix
  worker_count             = var.cluster_config.worker_count
  master_ingress_ports     = var.cluster_config.master_ingress_ports
  worker_ingress_ports     = var.cluster_config.worker_ingress_ports
  tags                     = merge(var.base_tags, var.cluster_config.tags)
}
module "iam" {
  source            = "./modules/iam"
  node_role_name    = var.iam.node_role_name
  node_profile_name = var.iam.node_profile_name
}

module "load_balancer" {
  source = "./modules/load-balancer"

  name                       = var.load_balancer.name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  load_balancer_type         = var.load_balancer.load_balancer_type
  internal                   = var.load_balancer.internal
  enable_deletion_protection = var.load_balancer.enable_deletion_protection
  idle_timeout               = var.load_balancer.idle_timeout
  target_groups              = var.load_balancer.target_groups
  listeners                  = var.load_balancer.listeners
  security_group_rules       = try(var.load_balancer.security_group_rules, [])
  tags                       = try(merge(var.base_tags, var.load_balancer.tags, {}))
  is_hosted_zone             = var.load_balancer.is_hosted_zone
  hosted_zone_name           = var.load_balancer.hosted_zone_name
  domain_name                = var.load_balancer.domain_name
  depends_on                 = [module.k3s_cluster,module.helm_ingress]
}

module "aws_ccm" {
  source = "./modules/helm"

  release_name     = var.aws_ccm_config.release_name
  repository       = var.aws_ccm_config.repository
  chart            = var.aws_ccm_config.chart
  namespace        = var.aws_ccm_config.namespace
  create_namespace = var.aws_ccm_config.create_namespace
  values_file      = var.aws_ccm_config.values_file
  depends_on = [module.k3s_cluster]
}
module "helm_ingress" {
  source = "./modules/helm"

  release_name     = var.ingress_nginx_config.release_name
  repository       = var.ingress_nginx_config.repository
  chart            = var.ingress_nginx_config.chart
  namespace        = var.ingress_nginx_config.namespace
  create_namespace = var.ingress_nginx_config.create_namespace
  values_file      = var.ingress_nginx_config.values_file
  depends_on = [module.k3s_cluster,module.aws_ccm]
}
module "deployment" {
  source = "./modules/kubectl"
  providers = {
    kubectl = kubectl
  }
  depends_on = [module.k3s_cluster,module.helm_ingress]
}
