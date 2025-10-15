module "persistence_events_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.2"

  name       = "persistence-events.fifo"
  fifo_queue = true

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 10
  max_message_size           = 262144
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 1
  deduplication_scope        = "messageGroup"
  fifo_throughput_limit      = "perMessageGroupId"
}

module "persistence_events_queue_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [module.persistence_events_queue]

  env                     = var.env
  region                  = var.aws_region
  queue_name              = module.persistence_events_queue.queue_name
  alarm_threshold_seconds = "1800" # 30 minutes
  alarm_sns_topic_arn     = aws_sns_topic.platform_alarms.arn
}

module "generated_jwt_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.2"

  name = "generated-jwt"

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 1209600
}

module "generated_jwt_queue_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [module.generated_jwt_queue]

  env                     = var.env
  region                  = var.aws_region
  queue_name              = module.generated_jwt_queue.queue_name
  alarm_threshold_seconds = "4500" # 1 hour 30 minutes
  alarm_sns_topic_arn     = aws_sns_topic.platform_alarms.arn
}

module "certified_mail_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.2"

  name       = "certified-mail.fifo"
  fifo_queue = true

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 1209600

  content_based_deduplication = true
  deduplication_scope         = "queue"
  fifo_throughput_limit       = "perQueue"
}

module "certified_mail_queue_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [module.certified_mail_queue]

  env                     = var.env
  region                  = var.aws_region
  queue_name              = module.certified_mail_queue.queue_name
  alarm_threshold_seconds = "1800" # 30 minutes
  alarm_sns_topic_arn     = aws_sns_topic.platform_alarms.arn
}

module "archived_agreements_for_purposes_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.2"

  name = "archived-agreements-for-purposes"

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 1209600
}

module "archived_agreements_for_purposes_queue_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [module.archived_agreements_for_purposes_queue]

  env                     = var.env
  region                  = var.aws_region
  queue_name              = module.archived_agreements_for_purposes_queue.queue_name
  alarm_threshold_seconds = "4500" # 1 hour 30 minutes
  alarm_sns_topic_arn     = aws_sns_topic.platform_alarms.arn
}

module "archived_agreements_for_eservices_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "v4.0.2"

  name = "archived-agreements-for-eservices"

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 1209600
}

module "archived_agreements_for_eservices_queue_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [module.archived_agreements_for_eservices_queue]

  env                     = var.env
  region                  = var.aws_region
  queue_name              = module.archived_agreements_for_eservices_queue.queue_name
  alarm_threshold_seconds = "4500" # 1 hour 30 minutes
  alarm_sns_topic_arn     = aws_sns_topic.platform_alarms.arn
}

module "s3_replication_failed_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.2.1"

  name = "s3-replication-failed-events"

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 30
  max_message_size           = 262144
  message_retention_seconds  = 1209600

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "S3EventsPublish"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]

      conditions = [{
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }]
    }
  }
}

module "jwt_details_new_s3_object_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.2"

  name = format("%s-jwt-details-new-s3-object-%s", local.project, var.env)

  sqs_managed_sse_enabled = false

  visibility_timeout_seconds = 10
  max_message_size           = 262144  # 256 KiB - the maximum
  message_retention_seconds  = 1209600 # 14 days - the maximum
  receive_wait_time_seconds  = 1

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "SnsEventsPublish"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      conditions = [{
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          aws_sns_topic.jwt_details_new_s3_object.arn
        ]
      }]
    }
  }
}

resource "aws_sns_topic_subscription" "jwt_details_new_s3_object" {
  topic_arn            = aws_sns_topic.jwt_details_new_s3_object.arn
  protocol             = "sqs"
  endpoint             = module.jwt_details_new_s3_object_queue.queue_arn
  raw_message_delivery = true
}

module "jwt_details_new_s3_object_queue_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [module.jwt_details_new_s3_object_queue]

  env                     = var.env
  region                  = var.aws_region
  queue_name              = module.jwt_details_new_s3_object_queue.queue_name
  alarm_threshold_seconds = 15 * 60 # The application will wait 10 minute to sign a batch of file in the same zip.
  alarm_sns_topic_arn     = aws_sns_topic.platform_alarms.arn
}
