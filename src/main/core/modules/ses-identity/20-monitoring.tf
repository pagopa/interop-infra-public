data "aws_cloudwatch_event_bus" "default" {
  name = "default"
}

locals {
  ses_identity_subdomain = element(split(".", var.ses_identity_name), 0)
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
  event_destination_name = format("%s-eventbridge", local.configuration_set_name)
  event_bus_arn          = data.aws_cloudwatch_event_bus.default.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = format("/aws/ses/events/%s", local.ses_identity_subdomain)
  retention_in_days = var.env == "prod" ? 90 : 30
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]
    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*"
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*:*"
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_document = data.aws_iam_policy_document.this.json
  policy_name     = format("interop-%s-publish-ses-events-to-cloudwatch", local.ses_identity_subdomain)
}

resource "aws_cloudwatch_event_rule" "this" {
  name        = format("interop-%s-capture-ses-events", local.ses_identity_subdomain)
  description = "This rule is used to capture SES events"

  event_pattern = jsonencode({
    source      = ["aws.ses"],
    detail-type = ["Email Bounced", "Email Complaint Received", "Email Delivered", "Email Sent", "Email Rejected", "Email Delivery Delayed"],
    detail = {
      mail = {
        sourceArn = [aws_sesv2_email_identity.this.arn]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  target_id = format("interop-%s-publish-ses-events-to-cloudwatch", local.ses_identity_subdomain)

  rule = aws_cloudwatch_event_rule.this.name
  arn  = aws_cloudwatch_log_group.this.arn
}

# Workaround because Terraform does not support event destination for EventBridge yet.
resource "null_resource" "eventbridge_ses_event_destination" {
  triggers = {
    event_target = aws_cloudwatch_event_target.this.rule
  }

  provisioner "local-exec" {
    command = <<EOF
aws sesv2 create-configuration-set-event-destination --configuration-set-name ${local.configuration_set_name} --event-destination-name ${local.event_destination_name} --event-destination '{
  "Enabled": true,
  "MatchingEventTypes": ["SEND", "REJECT", "BOUNCE", "COMPLAINT", "DELIVERY", "DELIVERY_DELAY"],
  "EventBridgeDestination": {
    "EventBusArn": "${local.event_bus_arn}"
  }
}'
EOF
  }
}

resource "aws_cloudwatch_metric_alarm" "reject" {
  count = (var.create_alarms && var.sns_topics_arn != null) ? 1 : 0

  alarm_name          = format("ses-%s-reject", local.ses_identity_subdomain)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "Reject"
  namespace           = "AWS/SES"
  period              = "60"
  evaluation_periods  = "60"
  threshold           = "1"
  datapoints_to_alarm = "1"
  statistic           = "Sum"
  alarm_description   = "This metric checks for reject rate"
  alarm_actions       = var.sns_topics_arn
  dimensions = {
    Identity = aws_sesv2_email_identity.this.email_identity
  }
}

resource "aws_cloudwatch_metric_alarm" "bounce" {
  count = (var.create_alarms && var.ses_reputation_sns_topics_arn != null) ? 1 : 0

  alarm_name          = format("ses-%s-bounce", local.ses_identity_subdomain)
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = "60"
  evaluation_periods  = "60"
  threshold           = "0"
  datapoints_to_alarm = "1"
  statistic           = "Average"
  alarm_description   = "This metric checks for bounce rate"
  alarm_actions       = var.ses_reputation_sns_topics_arn
  dimensions = {
    Identity = aws_sesv2_email_identity.this.email_identity
  }
}

resource "aws_cloudwatch_metric_alarm" "complaint" {
  count = (var.create_alarms && var.ses_reputation_sns_topics_arn != null) ? 1 : 0

  alarm_name          = format("ses-%s-complaint", local.ses_identity_subdomain)
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "Reputation.ComplaintRate"
  namespace           = "AWS/SES"
  period              = "60"
  evaluation_periods  = "60"
  threshold           = "0"
  datapoints_to_alarm = "1"
  statistic           = "Average"
  alarm_description   = "This metric checks for complaint rate"
  alarm_actions       = var.ses_reputation_sns_topics_arn
  dimensions = {
    Identity = aws_sesv2_email_identity.this.email_identity
  }
}