# variable "service_name" {
#   type        = string
#   description = "Name of the Kubernetes service"
# }

# variable "namespace" {
#   type        = string
#   description = "Namespace to deploy the service"
#   default     = "default"
# }

# variable "service_type" {
#   type        = string
#   description = "Service type (ClusterIP, NodePort, LoadBalancer)"
#   default     = "LoadBalancer"
# }

# variable "selector" {
#   type        = map(string)
#   description = "Selector labels to match pods"
# }

# variable "ports" {
#   type = list(object({
#     port        = number
#     target_port = number
#     protocol    = string
#   }))
#   description = "List of ports to expose"
# }

# variable "annotations" {
#   type        = map(string)
#   description = "Annotations for the service"
#   default     = {}
# }