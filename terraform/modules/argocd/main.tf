variable "values_file" { type = string }

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.2"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600
  wait             = true

  values = [
    file(var.values_file)
  ]
}

resource "null_resource" "wait_argocd" {
  provisioner "local-exec" {
    command = "kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s"
  }
  depends_on = [helm_release.argocd]
}
