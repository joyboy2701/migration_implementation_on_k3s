variable "release_name" {
  type        = string
  description = "Name of the Helm release"
  default     = "aws-load-balancer-controller"
}

variable "chart" {
  type        = string
  description = "Name of the Helm chart"
  default     = "aws-load-balancer-controller"
}

variable "repository" {
  type        = string
  description = "Helm chart repository URL"
  default     = "https://aws.github.io/eks-charts"
}

variable "namespace" {
  type        = string
  description = "Namespace to deploy the Helm chart"
  default     = "kube-system"
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create the namespace if it does not exist"
  default     = true
}

variable "values_file" {
  type        = string
  description = "Path to Helm values.yaml file"
  default     = ""  # do not use ${path.module}
}


variable "values_override" {
  type    = any
  default = {}
}