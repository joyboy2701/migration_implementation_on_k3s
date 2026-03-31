# ------------------------------
# VPC Configuration
# ------------------------------
vpc = {
  vpc_name                = "k3s-vpc"
  vpc_cidr                = "10.0.0.0/24"
  public_subnet_cidrs     = ["10.0.0.0/26", "10.0.0.64/26"]
  private_subnet_cidrs    = ["10.0.0.128/26", "10.0.0.192/26"]
  cidr_block              = "0.0.0.0/0"
  domain                  = "vpc"
  map_public_ip_on_launch = true
  enable_dns_support      = true
  dns_host_name           = true
  tags = {
    "kubernetes.io/cluster/k3s-cluster" = "shared"
  }
}
base_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
}
aws_region = "us-east-2"
bastion = {
  ami_id                 = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  user_data_file         = "./user_data.sh"
  bastion_sg_name        = "bastion-sg"
  bastion_sg_egress_cidr = ["0.0.0.0/0"]
  bastion_name           = "bastion-host"
  bastion_role           = "bastion"
  bastion_cluster        = "k8s-cluster"
  key_name               = "zok"
}
