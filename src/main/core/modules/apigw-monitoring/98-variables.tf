variable "env" {
  type        = string
  description = "Environment name"
}

variable "apigw_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms notifications"
  type        = string
}

variable "alarm_5xx_threshold" {
  description = "Threshold to trigger 5xx APIGW alarm"
  type        = number
}

variable "alarm_5xx_period" {
  description = "Period (in seconds) over which the 5xx APIGW alarm statistic is applied"
  type        = number
}

variable "alarm_5xx_eval_periods" {
  description = "Number of periods to evaluate for the 5xx APIGW alarm"
  type        = number
}

variable "alarm_5xx_datapoints" {
  description = "Number of breaching datapoints in the evaluation period to trigger the 5xx APIGW alarm"
  type        = number
}




