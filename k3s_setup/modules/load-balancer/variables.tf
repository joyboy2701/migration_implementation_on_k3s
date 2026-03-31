variable "name" {
  type        = string
  description = "Name prefix for ALB and related resources"
}
variable "vpc_id" {
  type        = string
  description = "VPC ID where ALB will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets to attach the ALB to"
}
variable "load_balancer_type" {
  type        = string
  description = "load balancer type"
}
variable "internal" {
  type        = bool
  description = "Whether the ALB is internal"
  default     = true
}
variable "enable_deletion_protection" {
  type    = bool
  default = false
}
variable "idle_timeout" {
  type        = number
  description = "Timeout for Load Balancer"
}

variable "security_group_rules" {
  description = "List of security group rules"
  type = list(object({
    type            = string # "ingress" or "egress"
    description     = optional(string)
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
    self            = optional(bool, false)

  }))
  default = []
}
variable "tags" {
  description = "Tags for the security group"
  type        = map(string)
  default     = {}
}

# variable "target_groups" {
#   description = "Map of target group configurations"
#   type = map(object({
#     name        = string
#     port        = number
#     protocol    = string
#     target_type = string
#     health_check = optional(object({
#       path                = optional(string)
#       matcher             = optional(string)
#       interval            = optional(number)
#       healthy_threshold   = optional(number)
#       unhealthy_threshold = optional(number)
#       timeout             = optional(number)
#       port                = optional(string)
#     }))
#   }))
#   default = {}
# }
variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    name        = string
    port        = number
    protocol    = string
    target_type = string

    targets = optional(list(object({
      ip   = string
      port = number
    })))

    health_check = optional(object({
      path                = optional(string)
      matcher             = optional(string)
      interval            = optional(number)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      timeout             = optional(number)
      port                = optional(string)
    }))
  }))
  default = {}
}

# Simplified module variable
variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port             = number
    protocol         = string
    target_group_key = string
    ssl_policy       = optional(string)
    certificate_arn  = optional(string)

    # Simple rules for path-based routing
    rules = optional(map(object({
      priority         = number
      path_patterns    = list(string) # ["/nginx/*", "/api/*"]
      target_group_key = string
    })), {})
  }))
  default = null
}
variable "hosted_zone_name" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "is_hosted_zone" {
  type = bool
}