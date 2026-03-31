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
    tags=optional(map(string), {})
  })
}
variable "base_tags" {
  type = map(string)
}
variable "aws_region" {
  type = string
}
variable "cluster_config" {
  description = "Complete configuration for K3s cluster infrastructure"

  type = object({

    k3s_sg_name               = string
    k3s_master_instance_type  = string
    k3s_master_name           = string

    k3s_worker_instance_type  = string
    worker_ingress_ports     = list(number)
    master_ingress_ports     = list(number)
    k3s_worker_name_prefix    = string
    worker_count              = number
    tags                      = optional(map(string), {})
  })
}
variable "iam" {
  description = "IAM configuration"
  type = object({
    node_role_name           = string
    node_profile_name        = string
  })
}


variable "load_balancer" {
  description = "Configurations for load balancer with support for multiple services"
  type = object({
    name                       = string
    load_balancer_type         = string
    internal                   = bool
    enable_deletion_protection = optional(bool, false)
    idle_timeout               = number

    # Security group rules for ALB
    security_group_rules = optional(list(object({
      type            = string # "ingress" or "egress"
      description     = optional(string)
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string))
      security_groups = optional(list(string))
      self            = optional(bool, false)
    })), [])

    # Target groups - one per service
    target_groups = map(object({
      name        = string
      port        = number
      protocol    = string
      target_type = optional(string, "ip")
       targets = optional(list(object({
        ip   = string
        port = optional(number)
      })), [])
      health_check = optional(object({ # ← Change from individual fields
        path                = optional(string)
        matcher             = optional(string)
        interval            = optional(number)
        healthy_threshold   = optional(number)
        unhealthy_threshold = optional(number)
        timeout             = optional(number)
        port                = optional(string)
      }))
    }))

    is_hosted_zone = bool
    hosted_zone_name = optional(string)
    domain_name = optional(string)

    # Listeners
    listeners = map(object({
      port                = number
      protocol            = string
      target_group_key    = string # Key from target_groups map
      ssl_policy          = optional(string)
      certificate_arn     = optional(string)
      default_action_type = optional(string, "forward")

      rules = optional(map(object({
        priority         = number
        path_patterns    = list(string) # ["/nginx/*", "/api/*"]
        target_group_key =optional(string)
      })), {})
    }))

    tags = optional(map(string), {})
  })
}

variable "aws_ccm_config" {
  description = "Configuration for AWS Cloud Controller Manager Helm release"
  type = object({
    release_name     = string
    repository       = string
    chart            = string
    namespace        = string
    create_namespace = bool
    values_file      = string
  })
}

variable "ingress_nginx_config" {
  description = "Configuration for ingress-nginx Helm release"
  type = object({
    release_name     = string
    repository       = string
    chart            = string
    namespace        = string
    create_namespace = bool
    values_file      = string
  })
}