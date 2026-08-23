variable "values_file" { type = string }

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "69.6.0"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600
  wait             = true

  values = [
    file(var.values_file)
  ]
}
