resource "kubernetes_namespace_v1" "env_analytics" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  metadata {
    name = var.analytics_k8s_namespace
  }
}