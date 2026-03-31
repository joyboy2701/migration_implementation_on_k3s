

resource "helm_release" "chart" {
  name             = var.release_name
  repository       = var.repository
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [file(var.values_file)]
   disable_openapi_validation = true
   
}