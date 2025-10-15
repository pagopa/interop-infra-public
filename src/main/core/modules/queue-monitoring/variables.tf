variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  description = "Environment identificator"
  type        = string
}

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for alarms actions"
  type        = string
  default     = ""
}

variable "alarm_threshold_seconds" {
  description = "Threshold (seconds) to trigger the queue's message age alarm"
  type        = string
}

variable "alarm_evaluation_periods" {
  description = "Evaluation period"
  type        = string
  default     = "1"
}

variable "alarm_metric_name" {
  description = "Alarm Metric Name"
  type        = string
  default     = "ApproximateAgeOfOldestMessage"
}

variable "alarm_period" {
  description = "Alarm Period"
  type        = string
  default     = "900" #15 minutes
}

variable "alarm_treat_missing_data" {
  description = "How to treat metrics missing data"
  type        = string
  default     = "notBreaching"
}

variable "alarm_statistic" {
  description = "The statistic to apply to the alarm's associated metric"
  type        = string
  default     = "Maximum"
}

variable "datapoints_to_alarm" {
  description = "The number of datapoints that must be breaching to trigger the alarm"
  type        = number
  default     = 1
}
