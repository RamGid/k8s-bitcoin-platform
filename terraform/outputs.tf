output "cluster_name" {
  value = module.kind.cluster_name
}

output "urls" {
  value = {
    argocd   = "http://argocd.localhost"
    grafana  = "http://grafana.localhost"
  }
}
