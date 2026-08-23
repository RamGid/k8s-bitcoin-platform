variable "cluster_config" {
  type = object({
    name                = string
    kubernetes_version  = string
    control_plane_nodes = number
    worker_nodes        = number
    http_port           = number
    https_port          = number
  })
}

variable "kubeconfig_path" {
  type = string
}
