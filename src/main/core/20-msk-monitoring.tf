resource "aws_cloudwatch_metric_alarm" "msk_platform_events_cpu" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  alarm_name        = format("msk-cpu-%s", aws_msk_cluster.platform_events[0].cluster_name)
  alarm_description = "CPU usage for MSK ${aws_msk_cluster.platform_events[0].cluster_name}"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  metric_query {
    id          = "e1"
    label       = "Broker CPU"
    return_data = "true"

    expression = "SELECT MAX(CpuUser) FROM SCHEMA(\"AWS/Kafka\", \"Broker ID\", \"Cluster Name\")"
    period     = 60 # 1 minute
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  threshold           = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 2
}

resource "aws_cloudwatch_metric_alarm" "msk_platform_events_memory" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  alarm_name        = format("msk-memory-%s", aws_msk_cluster.platform_events[0].cluster_name)
  alarm_description = "Memory usage for MSK ${aws_msk_cluster.platform_events[0].cluster_name}"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  metric_query {
    id          = "e1"
    label       = "Broker memory"
    return_data = "true"

    expression = "SELECT MAX(HeapMemoryAfterGC) FROM SCHEMA(\"AWS/Kafka\", \"Broker ID\", \"Cluster Name\")"
    period     = 60 # 1 minute
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  threshold           = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 2
}

resource "aws_cloudwatch_metric_alarm" "msk_platform_events_disk_usage" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  alarm_name        = format("msk-disk-usage-%s", aws_msk_cluster.platform_events[0].cluster_name)
  alarm_description = "Disk usage for MSK ${aws_msk_cluster.platform_events[0].cluster_name}"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  metric_query {
    id          = "e1"
    label       = "Broker Disk Usage"
    return_data = "true"

    expression = "SELECT MAX(KafkaDataLogsDiskUsed) FROM SCHEMA(\"AWS/Kafka\", \"Broker ID\", \"Cluster Name\")"
    period     = 60 # 1 minute
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  threshold           = 30
  evaluation_periods  = 5
  datapoints_to_alarm = 2
}
