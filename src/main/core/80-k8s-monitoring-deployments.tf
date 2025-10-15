module "k8s_deployment_monitoring" {
  for_each = toset(concat(var.k8s_monitoring_deployments_names, var.k8s_monitoring_internal_deployments_names))

  source = "git@github.com:pagopa/interop-infra-commons//terraform/modules/k8s-workload-monitoring?ref=v1.27.7"

  eks_cluster_name  = module.eks.cluster_name
  k8s_namespace     = var.env
  kind              = "Deployment"
  k8s_workload_name = each.key
  sns_topics_arns   = [aws_sns_topic.platform_alarms.arn]

  create_pod_availability_alarm = false
  create_pod_readiness_alarm    = true
  create_performance_alarm      = true
  create_app_logs_errors_alarm  = true

  avg_cpu_alarm_threshold           = 70
  avg_memory_alarm_threshold        = 70
  performance_alarms_period_seconds = 300 # 5 minutes

  create_dashboard = true

  cloudwatch_app_logs_errors_metric_name      = contains(var.k8s_monitoring_internal_deployments_names, each.key) ? aws_cloudwatch_log_metric_filter.eks_app_logs_errors.metric_transformation[0].name : null
  cloudwatch_app_logs_errors_metric_namespace = contains(var.k8s_monitoring_internal_deployments_names, each.key) ? aws_cloudwatch_log_metric_filter.eks_app_logs_errors.metric_transformation[0].namespace : null
}

module "k8s_adot_monitoring" {
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/k8s-workload-monitoring?ref=v1.27.7"

  eks_cluster_name  = module.eks.cluster_name
  k8s_namespace     = "aws-observability"
  kind              = "Deployment"
  k8s_workload_name = "adot-collector"
  sns_topics_arns   = [aws_sns_topic.platform_alarms.arn]

  create_pod_availability_alarm = false
  create_pod_readiness_alarm    = true
  create_performance_alarm      = true
  create_app_logs_errors_alarm  = true

  avg_cpu_alarm_threshold           = 70
  avg_memory_alarm_threshold        = 70
  performance_alarms_period_seconds = 300 # 5 minutes

  create_dashboard = true
}
