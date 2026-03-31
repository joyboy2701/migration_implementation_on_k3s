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
cluster_config = {
  k3s_sg_name = "k3s-sg"

  k3s_master_instance_type = "t3.small"
  k3s_master_name          = "k3s-master"
  master_ingress_ports     = [6443, 10250, 8472]
  worker_ingress_ports     = [6443, 8472, 10250]
  k3s_worker_instance_type = "t3.small"
  k3s_worker_name_prefix   = "k3s-worker"
  worker_count             = 1
  tags = {
    "kubernetes.io/cluster/k3s-cluster" = "owned"
  }
}
iam = {
  node_role_name    = "k3s-ssm-role"
  node_profile_name = "k3s-ssm-profile"
}


load_balancer = {
  name               = "cluster-public-alb"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60
  is_hosted_zone     = false
  domain_name        = "zubair"
  hosted_zone_name   = "danialdevops.com"
  security_group_rules = [
    {
      type        = "ingress"
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "egress"
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  target_groups = {
    api = {
      name        = "api-tg"
      port        = 80
      protocol    = "HTTP"
      target_type = "ip"

      targets = [
        {
          ip   = "10.0.0.150"
          port = 80
        },
        {
          ip   = "10.0.0.210"
          port = 80
        }
      ]
    }
  }

  listeners = {
    http = {
      port             = 80
      protocol         = "HTTP"
      target_group_key = "api"
    }
  }

  tags = {
    Application = "k3s-cluster"
  }
}
aws_ccm_config = {
  release_name     = "aws-cloud-controller-manager"
  repository       = "https://kubernetes.github.io/cloud-provider-aws"
  chart            = "aws-cloud-controller-manager"
  namespace        = "kube-system"
  create_namespace = false
  values_file      = "./modules/helm/values_ccm.yaml"
}

ingress_nginx_config = {
  release_name            = "ingress-nginx"
  repository              = "https://kubernetes.github.io/ingress-nginx"
  chart                   = "ingress-nginx"
  namespace               = "ingress-nginx"
  create_namespace        = true
  values_file             = "./modules/helm/values.yaml"
  nlb_internal            = "true"
  nlb_target_type         = "ip"
  nlb_private_ips         = ["10.0.0.150", "10.0.0.210"]
  cross_zone_enabled      = "true"
  external_traffic_policy = "Cluster"
}
