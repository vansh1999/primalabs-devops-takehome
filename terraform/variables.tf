variable "namespace" {
  type    = string
  default = "primalabs"
}

variable "app_name" {
  type    = string
  default = "primalabs-app"
}

variable "app_image" {
  type    = string
  default = "primalabs-app:v1"
}

variable "app_replicas" {
  type    = number
  default = 2
}

variable "monitoring_namespace" {
  type    = string
  default = "monitoring"
}


variable "metrics_server_chart_version" {

  type = string

  default = "3.13.0"

}

variable "kube_prometheus_stack_chart_version" {

  type = string

  default = "77.12.0"

}