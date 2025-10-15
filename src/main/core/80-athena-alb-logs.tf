resource "aws_athena_named_query" "alb_logs_5xx" {
  name      = "alb-logs-5xx"
  workgroup = aws_athena_workgroup.interop_queries.id
  database  = "default"

  query = <<-EOT
    SELECT * FROM alb_logs
    WHERE elb = '${data.aws_lb.backend_alb.arn_suffix}'
    AND elb_status_code >= 500
    AND day = '' -- 'yyyy/mm/dd'
  EOT
}
