variable "base_tags" {
  type = map(string)
}
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
variable "bastion" {
  description = "Bastion host configuration"
  type = object({
    instance_type          = string
    user_data_file         = string
    bastion_sg_name        = string
    bastion_sg_egress_cidr = list(string)
    bastion_name           = string
    bastion_role           = string
    bastion_cluster        = string
    key_name               = string
  })
}
variable "aws_region" {
  type = string
}