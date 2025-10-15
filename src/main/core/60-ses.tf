locals {
  notifications_recipients_regex = {
    dev  = ["*@pagopa.it", "*@grupposcai.it"]
    qa   = ["*@pagopa.it", "*@grupposcai.it"]
    vapt = ["*@pagopa.it", "*@aizoongroup.com"]
    test = ["*@pagopa.it"]
  }
}

module "reports_ses_identity" {
  source = "./modules/ses-identity"

  env                           = var.env
  ses_identity_name             = format("reports.%s", aws_route53_zone.interop_public.name)
  hosted_zone_id                = aws_route53_zone.interop_public.zone_id
  create_alarms                 = true
  sns_topics_arn                = [aws_sns_topic.platform_alarms.arn]
  ses_reputation_sns_topics_arn = [aws_sns_topic.platform_alarms.arn, aws_sns_topic.ses_reputation.arn]
}

module "reports_ses_iam_policy" {
  source = "./modules/ses-iam-policy"

  env                            = var.env
  ses_iam_policy_name            = format("interop-reports-ses-policy-%s", var.env)
  ses_identity_arn               = module.reports_ses_identity.ses_identity_arn
  ses_configuration_set_arn      = module.reports_ses_identity.ses_configuration_set_arn
  allowed_recipients_regex       = ["*@pagopa.it"]
  allowed_from_addresses_literal = [format("noreply@%s", module.reports_ses_identity.ses_identity_name)]
}

module "notifiche_ses_identity" {
  source = "./modules/ses-identity"

  env                           = var.env
  ses_identity_name             = format("notifiche.%s", aws_route53_zone.interop_public.name)
  hosted_zone_id                = aws_route53_zone.interop_public.zone_id
  create_alarms                 = true
  sns_topics_arn                = [aws_sns_topic.platform_alarms.arn]
  ses_reputation_sns_topics_arn = [aws_sns_topic.platform_alarms.arn, aws_sns_topic.ses_reputation.arn]
}

module "notifiche_ses_iam_policy" {
  source = "./modules/ses-iam-policy"

  env                            = var.env
  ses_iam_policy_name            = format("interop-notifiche-ses-%s", var.env)
  ses_identity_arn               = module.notifiche_ses_identity.ses_identity_arn
  ses_configuration_set_arn      = module.notifiche_ses_identity.ses_configuration_set_arn
  allowed_recipients_regex       = try(local.notifications_recipients_regex[var.env], null)
  allowed_from_addresses_literal = [format("noreply@%s", module.notifiche_ses_identity.ses_identity_name)]
}

module "internal_ses_identity" {
  count  = var.env == "dev" ? 1 : 0
  source = "./modules/ses-identity"

  env                           = var.env
  ses_identity_name             = format("internal.%s", aws_route53_zone.interop_public.name)
  hosted_zone_id                = aws_route53_zone.interop_public.zone_id
  create_alarms                 = true
  sns_topics_arn                = [aws_sns_topic.platform_alarms.arn]
  ses_reputation_sns_topics_arn = [aws_sns_topic.platform_alarms.arn, aws_sns_topic.ses_reputation.arn]
}
