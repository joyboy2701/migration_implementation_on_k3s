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

  values_override = {
    namespace = "kube-system"

    args = [
      "--v=2",
      "--cloud-provider=aws",
      "--cluster-cidr=10.42.0.0/16"
    ]

    nodeSelector = {
      "node-role.kubernetes.io/control-plane" = "true"
    }
  }
}
ingress_nginx_config = {
  release_name     = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  values_override = {
    controller = {
      service = {
        type = "LoadBalancer"

        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"                   = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-internal"               = "true"
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"        = "ip"
          "service.beta.kubernetes.io/aws-load-balancer-private-ipv4-addresses" = "10.0.0.150,10.0.0.210"
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
        }

        externalTrafficPolicy = "Cluster"
      }

      ingressClassResource = {
        name    = "nginx"
        enabled = true
        default = true
      }

      admissionWebhooks = {
        enabled       = true
        failurePolicy = "Ignore"
      }
    }
  }
}