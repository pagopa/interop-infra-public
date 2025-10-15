locals {
  app_audit_consumer_groups = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? {
    application-audit-analytics-writer = {
      consumer_group = format("%s-application-audit-analytics-writer", var.analytics_k8s_namespace),
      topic          = format("%s_application.audit", var.env)
    },
    application-audit-archiver = {
      consumer_group = format("%s-application-audit-archiver", var.analytics_k8s_namespace),
      topic          = format("%s_application.audit", var.env)
    }
  } : {}
}

resource "aws_cloudwatch_metric_alarm" "max_offsetlag" {
  for_each = local.app_audit_consumer_groups

  alarm_name          = "msk-max-offsetlag-topic-for-${each.value.consumer_group}"
  alarm_description   = "Max offset lag in the ${each.value.topic} topic for the ${each.value.consumer_group} consumer group"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.msk_monitoring_app_audit_evaluation_periods
  metric_name         = "MaxOffsetLag"
  namespace           = "AWS/Kafka"
  period              = var.msk_monitoring_app_audit_period_seconds
  statistic           = "Maximum"
  threshold           = var.msk_monitoring_app_audit_max_offset_lag_threshold
  alarm_actions       = [aws_sns_topic.analytics_alarms.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    "Cluster Name"   = data.aws_msk_cluster.platform_events.cluster_name
    "Consumer Group" = each.value.consumer_group
    "Topic"          = each.value.topic
  }
  datapoints_to_alarm = "3"
}
