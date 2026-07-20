variable "namespace" {
  description = "Namespace where kube-prometheus-stack will be installed"
  type        = string
}

variable "metrics_server_chart_version" {
  description = "Metrics Server Helm chart version"
  type        = string
}

variable "kube_prometheus_stack_chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
}