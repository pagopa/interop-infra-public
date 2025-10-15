resource "aws_cloudwatch_metric_alarm" "redshift_cpu_utilization" {
  count = local.deploy_redshift_cluster ? 1 : 0

  alarm_name        = format("redshift-%s-cpu-utilization", aws_redshift_cluster.analytics[0].cluster_identifier)
  alarm_description = "Max CPU utilization among the nodes of the ${aws_redshift_cluster.analytics[0].cluster_identifier} Redshift cluster"

  alarm_actions = [aws_sns_topic.analytics_alarms.arn]

  metric_query {
    id          = "e1"
    label       = "Max CPU utilization"
    return_data = "true"

    expression = "SELECT MAX(CPUUtilization) FROM SCHEMA(\"AWS/Redshift\", \"ClusterIdentifier\", \"NodeID\")"
    period     = 60 # 1 minute
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  threshold           = 70
  evaluation_periods  = 5
  datapoints_to_alarm = 3
}

resource "aws_cloudwatch_metric_alarm" "redshift_health_status" {
  count = local.deploy_redshift_cluster ? 1 : 0

  alarm_name        = format("redshift-%s-health-status", aws_redshift_cluster.analytics[0].cluster_identifier)
  alarm_description = "Health status of the ${aws_redshift_cluster.analytics[0].cluster_identifier} Redshift cluster"

  alarm_actions = [aws_sns_topic.analytics_alarms.arn]

  metric_name = "HealthStatus"
  namespace   = "AWS/Redshift"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.analytics[0].cluster_identifier
  }

  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  treat_missing_data  = "missing"

  threshold           = 1
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 2
}

resource "aws_cloudwatch_metric_alarm" "redshift_maintenance_mode" {
  count = local.deploy_redshift_cluster ? 1 : 0

  alarm_name        = format("redshift-%s-maintenance-mode", aws_redshift_cluster.analytics[0].cluster_identifier)
  alarm_description = "Maintenance mode of the ${aws_redshift_cluster.analytics[0].cluster_identifier} Redshift cluster"

  alarm_actions = [aws_sns_topic.analytics_alarms.arn]

  metric_name = "MaintenanceMode"
  namespace   = "AWS/Redshift"
  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.analytics[0].cluster_identifier
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Maximum"
  treat_missing_data  = "missing"

  threshold           = 1
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 2
}

resource "aws_cloudwatch_metric_alarm" "redshift_disk_space_used" {
  count = local.deploy_redshift_cluster ? 1 : 0

  alarm_name        = format("redshift-%s-disk-space-used", aws_redshift_cluster.analytics[0].cluster_identifier)
  alarm_description = "Max percentage of disk space used among the nodes of the ${aws_redshift_cluster.analytics[0].cluster_identifier} Redshift cluster"

  alarm_actions = [aws_sns_topic.analytics_alarms.arn]

  metric_query {
    id          = "e1"
    label       = "Max disk space used"
    return_data = "true"

    expression = "SELECT MAX(PercentageDiskSpaceUsed) FROM SCHEMA(\"AWS/Redshift\", \"ClusterIdentifier\", \"NodeID\")"
    period     = 60 # 1 minute
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  threshold           = 40
  evaluation_periods  = 5
  datapoints_to_alarm = 2
}
