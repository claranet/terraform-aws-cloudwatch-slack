variable "slack_webhook_url" {
}

provider "aws" {
  region = "eu-west-1"
}

locals {
  name = "terraform-aws-cloudwatch-slack-tests-basic"
}

resource "aws_sns_topic" "test" {
  name = local.name
}

module "test" {
  source = "../../"

  name          = local.name
  sns_topic_arn = aws_sns_topic.test.arn
  slack_url     = var.slack_webhook_url

  lambda_layers = ["arn:aws:lambda:::awslayer:AmazonLinux1803"]
}

resource "aws_cloudwatch_metric_alarm" "test" {
  alarm_name        = local.name
  alarm_description = "Testing the terraform-aws-cloudwatch-slack module"

  metric_name = "Invocations"
  namespace   = "AWS/Lambda"

  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions             = [aws_sns_topic.test.arn]
  insufficient_data_actions = [aws_sns_topic.test.arn]
  ok_actions                = [aws_sns_topic.test.arn]
}

