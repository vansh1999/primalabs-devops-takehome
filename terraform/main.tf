resource "kubernetes_namespace" "primalabs" {
  metadata {
    name = var.namespace
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  namespace = var.monitoring_namespace

  metrics_server_chart_version         = var.metrics_server_chart_version
  kube_prometheus_stack_chart_version  = var.kube_prometheus_stack_chart_version
}