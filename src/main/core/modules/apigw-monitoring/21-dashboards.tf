resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = replace(format("apigw-%s", var.apigw_name), ".", "-")
  dashboard_body = templatefile("${path.module}/apigw-dashboard.tpl.json", {
    Region    = data.aws_region.current.name
    ApiGwName = var.apigw_name
  })
}
