terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
    }
  }
}

resource "kind_cluster" "platform_cluster" {
  name            = var.cluster_config.name
  node_image      = "kindest/node:${var.cluster_config.kubernetes_version}"
  kubeconfig_path = pathexpand(var.kubeconfig_path)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = var.cluster_config.http_port
      }
      extra_port_mappings {
        container_port = 443
        host_port      = var.cluster_config.https_port
      }
    }

    dynamic "node" {
      for_each = range(var.cluster_config.worker_nodes)
      content {
        role = "worker"
      }
    }
  }
}
