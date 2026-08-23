variable "values_file" { type = string }

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.0"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 300
  wait             = true

  values = [
    file(var.values_file)
  ]
}

resource "null_resource" "wait_ingress" {
  provisioner "local-exec" {
    command = "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s"
  }
  depends_on = [helm_release.ingress_nginx]
}
