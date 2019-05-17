variable "name" {
  description = "The name to use for created resources"
  type        = "string"
}

variable "sns_topic_arn" {
  description = "The SNS topic to subscribe to"
  type        = "string"
}

variable "slack_url" {
  description = "The Slack webhook URL"
  type        = "string"
}

variable "tags" {
  default = {}
}

# Display options for the OK state:

variable "ok_user_name" {
  default = ""
}

variable "ok_user_emoji" {
  default = ""
}

variable "ok_status_emoji" {
  default = ":white_check_mark:"
}

# Display options for the ALARM state:

variable "alarm_user_name" {
  default = ""
}

variable "alarm_user_emoji" {
  default = ""
}

variable "alarm_status_emoji" {
  default = ":x:"
}

# Display options for the INSUFFICIENT_DATA state:

variable "insufficient_data_user_name" {
  default = ""
}

variable "insufficient_data_user_emoji" {
  default = ""
}

variable "insufficient_data_status_emoji" {
  default = ":x:"
}

# Lambda layers, for testing the new Lambda execution environment:
# https://aws.amazon.com/blogs/compute/upcoming-updates-to-the-aws-lambda-execution-environment/ 

variable "lambda_layers" {
  default = []
}
