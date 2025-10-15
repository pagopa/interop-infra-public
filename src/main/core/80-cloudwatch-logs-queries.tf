resource "aws_cloudwatch_query_definition" "app_logs_errors" {
  name = "Application-Logs-Errors"

  log_group_names = [var.eks_application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, @message
    | sort @timestamp asc
    | filter (@message like /ERROR/ or stream = "stderr")
    | filter @logStream not like /adot-collector/
    # | filter pod_app like /interop-be-authorization-server/
    # | filter pod_namespace = "dev" # for hybrid platform use "dev-refactor"
  EOT
}

resource "aws_cloudwatch_query_definition" "cid_tracker" {
  name = "CID-Tracker"

  log_group_names = [var.eks_application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, @message
    | sort @timestamp asc
    | parse @message "[CID=*]" as CID
    | filter CID = ""
    | display @message
  EOT
}

resource "aws_cloudwatch_query_definition" "waf_blocked_requests" {
  name = "WAF-Blocked-Requests"

  log_group_names = [aws_cloudwatch_log_group.waf.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter action = "BLOCK"
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_auth_server_5xx" {
  name = "APIGW-Auth-Server-5xx"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_auth_apigw.apigw_id}"
    | filter status like /5./
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_auth_server_waf_block" {
  name = "APIGW-Auth-Server-WAF-Block"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_auth_apigw.apigw_id}"
    | filter wafStatus != "200"
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_bff_5xx" {
  count = local.deploy_new_bff_apigw ? 0 : 1

  name = "APIGW-BFF-5xx"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_selfcare_apigw[0].apigw_id}"
    | filter status like /5./
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_bff_versioned_5xx" {
  count = local.deploy_new_bff_apigw ? 1 : 0

  name = "APIGW-BFF-5xx"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter (apigwId = "${module.interop_selfcare_1dot0_apigw[0].apigw_id}"%{if var.env == "dev"} or apigwId = "${module.interop_selfcare_0dot0_apigw[0].apigw_id}"%{endif})
    | filter status like /5./
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_bff_waf_block" {
  count = local.deploy_new_bff_apigw ? 0 : 1

  name = "APIGW-BFF-WAF-Block"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_selfcare_apigw[0].apigw_id}"
    | filter wafStatus != "200"
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_bff_versioned_waf_block" {
  count = local.deploy_new_bff_apigw ? 1 : 0

  name = "APIGW-BFF-WAF-Block"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter (apigwId = "${module.interop_selfcare_1dot0_apigw[0].apigw_id}"%{if var.env == "dev"} or apigwId = "${module.interop_selfcare_0dot0_apigw[0].apigw_id}"%{endif})
    | filter wafStatus != "200"
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_m2m_5xx" {
  name = "APIGW-M2M-5xx"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_api_1dot0_apigw.apigw_id}"
    | filter status like /5./
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_m2m_waf_block" {
  name = "APIGW-M2M-WAF-Block"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_api_1dot0_apigw.apigw_id}"
    | filter wafStatus != "200"
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_m2m_v2_5xx" {
  count = local.deploy_interop_api_v2 ? 1 : 0

  name = "APIGW-M2M-V2-5xx"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_api_v2_apigw[0].apigw_id}"
    | filter status like /5./
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_m2m_v2_waf_block" {
  count = local.deploy_interop_api_v2 ? 1 : 0

  name = "APIGW-M2M-V2-WAF-Block"

  log_group_names = [aws_cloudwatch_log_group.apigw_access_logs.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${module.interop_api_v2_apigw[0].apigw_id}"
    | filter wafStatus != "200"
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "generated_tokens" {
  name = "Auth-Server-Generated-Tokens"

  log_group_names = [var.eks_application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @logStream like /interop-be-authorization-server/
    | parse @message "[TYPE=*]" as token_type
    | filter token_type = "CONSUMER" # CONSUMER | API
    | filter @message like /Token generated/
    | sort @timestamp desc
    | display @timestamp, @message
  EOT
}

resource "aws_cloudwatch_query_definition" "auth_server_warnings" {
  name = "Auth-Server-Logs-Warnings"

  log_group_names = [var.eks_application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter pod_app like /interop-be-authorization-server/
    | filter @message like /WARN/
    | parse @message /\[CID=(?<cidValue>[^\]]*)\](?:\s*\[SPANID=[^\]]*\])?(?<errorMessage>.*?)","pod_app":/
    | stats count(*) as count by errorMessage
    | sort count desc
  EOT
}
