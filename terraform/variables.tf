variable "kubeconfig_path" {
  type        = string
  description = "Target local kubeconfig path."
  default     = "~/.kube/config"
}

variable "cluster_config_file" {
  type        = string
  default     = "../config/cluster.yaml"
}

variable "ingress_values_file" {
  type        = string
  default     = "../config/ingress-values.yaml"
}

variable "monitoring_values_file" {
  type        = string
  default     = "../config/monitoring-values.yaml"
}

variable "argocd_values_file" {
  type        = string
  default     = "../config/argocd-values.yaml"
}
