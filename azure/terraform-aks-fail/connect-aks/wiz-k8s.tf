
provider "helm" { 
  kubernetes {
    host = azurerm_kubernetes_cluster.default.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].cluster_ca_certificate)
  }
}

provider "wiz" {

}

variable "service_account_name" {
  type    = string
  default = "wiz-kube-connector"
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

resource "helm_release" "wiz_broker_rbac" {
  name       = "wiz-broker-rbac"
  repository = "https://wiz-sec.github.io/charts/"
  chart      = "wiz-broker"
  namespace = var.namespace

  set {
    name  = "installRbac"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }
  set {
    name  = "namespace"
    value = var.namespace
  }
}

# Added the namespace creation for wiz-monitoring
resource "kubernetes_namespace" "namespace" {
  metadata {
   name = var.namespace 
  }
}


data "kubernetes_service_account" "broker" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }

  depends_on = [
    helm_release.wiz_broker_rbac,
  ]
}


# Moved from data.tf to make a complete file (I am sure it can be moved back)
data "kubernetes_secret" "service_account_token" {
  metadata {
    name      = data.kubernetes_service_account.broker.default_secret_name
    namespace = var.namespace
  }
}

# Renamed from wiz-connector to connector to match the broker deployment
resource "wiz_kubernetes_connector" "connector" {
  name                         = var.namespace
  service_account_token        = data.kubernetes_secret.service_account_token.data.token
  server_certificate_authority = base64encode(data.kubernetes_secret.service_account_token.data["ca.crt"])
  server_endpoint              = azurerm_kubernetes_cluster.default.kube_config[0].host
  connector_type               = "aks"
  enabled                      = true
  is_private_cluster           = true
}

data "wiz_tunnel_server" "tunnel_domain" {}

resource "helm_release" "wiz_broker_deployment" {
  name         = "wiz-broker"
  repository   = "https://wiz-sec.github.io/charts/"
  chart        = "wiz-broker"
  reuse_values = true
  namespace = var.namespace

  set {
    name  = "installBroker"
    value = "true"
  }
  set {
    name  = "namespace"
    value = var.namespace
  }
  set {
    name  = "wizConnector.connectorId"
    value = wiz_kubernetes_connector.connector.id
  }
  set_sensitive {
    name  = "wizConnector.connectorToken"
    value = wiz_kubernetes_connector.connector.tunnel_token
  }
  set {
    name  = "wizConnector.targetDomain"
    value = wiz_kubernetes_connector.connector.tunnel_domain
  }
  set {
    name  = "wizConnector.targetIp"
    value = wiz_kubernetes_connector.connector.broker_host
  }
  set {
    name  = "wizConnector.targetPort"
    value = wiz_kubernetes_connector.connector.broker_port
  }
  set {
    name  = "wizConnector.tunnelServerAddress"
    value = data.wiz_tunnel_server.tunnel_domain.domain
  }
  set {
    name  = "wizConnector.tunnelServerPort"
    value = data.wiz_tunnel_server.tunnel_domain.port
  }
}