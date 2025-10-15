locals {
  # This locals are used in other files to easily define quicksight resources permissions


  quicksight_groups_arn_prefix = "arn:aws:quicksight:${var.quicksight_identity_center_region}:${data.aws_caller_identity.current.account_id}:group/default/${local.project}-${var.env}"

  quicksight_datasource_read_only_actions = [
    "quicksight:PassDataSource",
    "quicksight:DescribeDataSourcePermissions",
    "quicksight:DescribeDataSource"
  ]

  quicksight_datasource_read_write_actions = [
    "quicksight:PassDataSource",
    "quicksight:DescribeDataSourcePermissions",
    "quicksight:UpdateDataSource",
    "quicksight:UpdateDataSourcePermissions",
    "quicksight:DescribeDataSource",
    "quicksight:DeleteDataSource"
  ]

  quicksight_data_set_read_only_actions = [
    "quicksight:DescribeRefreshSchedule",
    "quicksight:ListIngestions",
    "quicksight:DescribeDataSetPermissions",
    "quicksight:PassDataSet",
    "quicksight:ListRefreshSchedules",
    "quicksight:DescribeDataSet",
    "quicksight:DescribeIngestion"
  ]

  quicksight_data_set_read_write_actions = [
    "quicksight:DeleteDataSet",
    "quicksight:UpdateDataSetPermissions",
    "quicksight:PutDataSetRefreshProperties",
    "quicksight:CreateRefreshSchedule",
    "quicksight:CancelIngestion",
    "quicksight:DeleteRefreshSchedule",
    "quicksight:PassDataSet",
    "quicksight:UpdateRefreshSchedule",
    "quicksight:ListRefreshSchedules",
    "quicksight:DescribeDataSetRefreshProperties",
    "quicksight:DescribeDataSet",
    "quicksight:CreateIngestion",
    "quicksight:DescribeRefreshSchedule",
    "quicksight:ListIngestions",
    "quicksight:DescribeDataSetPermissions",
    "quicksight:UpdateDataSet",
    "quicksight:DeleteDataSetRefreshProperties",
    "quicksight:DescribeIngestion"
  ]

  quicksight_analysis_read_write_actions = [
    "quicksight:RestoreAnalysis",
    "quicksight:UpdateAnalysisPermissions",
    "quicksight:DeleteAnalysis",
    "quicksight:DescribeAnalysisPermissions",
    "quicksight:QueryAnalysis",
    "quicksight:DescribeAnalysis",
    "quicksight:UpdateAnalysis"
  ]

  quicksight_dashboard_read_only_actions = [
    "quicksight:DescribeDashboard",
    "quicksight:ListDashboardVersions",
    "quicksight:QueryDashboard"
  ]

  quicksight_dashboard_read_write_actions = [
    "quicksight:DescribeDashboard",
    "quicksight:ListDashboardVersions",
    "quicksight:UpdateDashboardPermissions",
    "quicksight:QueryDashboard",
    "quicksight:UpdateDashboard",
    "quicksight:DeleteDashboard",
    "quicksight:DescribeDashboardPermissions",
    "quicksight:UpdateDashboardPublishedVersion"
  ]

  default_data_set_permissions = [
    {
      principal = "${local.quicksight_groups_arn_prefix}-quicksight-admins"
      actions   = local.quicksight_data_set_read_write_actions
    },
    {
      principal = "${local.quicksight_groups_arn_prefix}-quicksight-authors"
      actions   = local.quicksight_data_set_read_only_actions
    }
  ]

  default_dashboard_permissions = [
    {
      principal = "${local.quicksight_groups_arn_prefix}-quicksight-admins"
      actions   = local.quicksight_dashboard_read_write_actions
    },
    {
      principal = "${local.quicksight_groups_arn_prefix}-quicksight-authors"
      actions   = local.quicksight_dashboard_read_only_actions
    }
  ]
}
