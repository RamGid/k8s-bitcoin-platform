locals {
  cluster_cfg = yamldecode(file(var.cluster_config_file))
}

module "kind" {
  source          = "./modules/kind"
  cluster_config  = local.cluster_cfg
  kubeconfig_path = var.kubeconfig_path
}

module "ingress" {
  source      = "./modules/ingress"
  values_file = var.ingress_values_file
  depends_on  = [module.kind]
}

module "monitoring" {
  source      = "./modules/monitoring"
  values_file = var.monitoring_values_file
  depends_on  = [module.ingress] 
}

module "argocd" {
  source      = "./modules/argocd"
  values_file = var.argocd_values_file
  depends_on  = [module.ingress]
}
