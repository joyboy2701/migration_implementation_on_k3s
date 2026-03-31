variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for NGINX"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for K3s nodes"
  type        = string
}

variable "k3s_sg_name" {
  type = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}


variable "k3s_master_instance_type" {
  type = string
}

variable "k3s_worker_instance_type" {
  type = string
}

variable "worker_count" {
  type = number
}

variable "k3s_master_name" {
  type = string
}

variable "k3s_worker_name_prefix" {
  type = string
}
variable "region" {
  type = string
}
variable "iam_instance_profile_master" {
  type = string
}
variable "iam_instance_profile_worker" {
  type = string
}
variable "master_ingress_ports" {
  description = "List of ports to open on K3s master"
  type        = list(number)
}

variable "worker_ingress_ports" {
  description = "List of ports to open on K3s worker"
  type        = list(number)
}
variable "tags" {
  type = map(string)
}