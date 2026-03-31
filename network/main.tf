data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"] 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
# ------------------------------
# VPC Module
# ------------------------------
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
# ------------------------------
# Bastion Module
# ------------------------------
module "bastion" {
  source                 = "./modules/bastion"
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  ami_id                 = data.aws_ami.ubuntu22.id
  instance_type          = var.bastion.instance_type
  user_data_file         = var.bastion.user_data_file
  bastion_sg_name        = var.bastion.bastion_sg_name
  bastion_sg_egress_cidr = var.bastion.bastion_sg_egress_cidr
  bastion_name           = var.bastion.bastion_name
  bastion_role           = var.bastion.bastion_role
  bastion_cluster        = var.bastion.bastion_cluster
  key_name               = var.bastion.key_name

}
