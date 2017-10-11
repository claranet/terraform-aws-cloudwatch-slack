tf-aws-cloudwatch-slack
-----

Sends CloudWatch Alarm events to Slack.

Usage
-----

```js
// Create an SNS topic and send its events to the Luigi Slack channel.

resource "aws_sns_topic" "luigi_slack" {
  name = "luigi-slack-notifications"
}

module "cloudwatch_luigi_slack" {
  source = "../modules/tf-aws-cloudwatch-slack"

  name          = "luigi-slack-notifications"
  sns_topic_arn = "${aws_sns_topic.luigi_slack.arn}"
  slack_url     = "${var.luigi_slack_webhook_url}"

  tags = {
    Environment = "${var.envname}"
  }
}

// Create an SNS topic and send its events to the Customer’s Slack channel.

resource "aws_sns_topic" "customer_slack" {
  name = "customer-slack-notifications"
}

module "cloudwatch_customer_slack" {
  source = "../modules/tf-aws-cloudwatch-slack"

  name          = "customer-slack-notifications"
  sns_topic_arn = "${aws_sns_topic.customer_slack.arn}"
  slack_url     = "${var.customer_slack_webhook_url}"

  tags = {
    Environment = "${var.envname}"
  }
}

// Create CloudWatch Alarms and point them to the relevant SNS topics.

resource "aws_cloudwatch_metric_alarm" "database_backup" {
  alarm_name        = "${var.envname}-database-backup"
  alarm_description = "${var.envname} database backup"

  metric_name = "DatabaseBackupSize"
  namespace   = "BashtonBilling"

  dimensions {
    Environment = "${var.envname}"
  }

  statistic           = "Average"
  comparison_operator = "LessThanThreshold"
  threshold           = "0"
  period              = "${60 * 60 * 24}"
  evaluation_periods  = "1"
  treat_missing_data  = "missing"

  # Point to the Luigi SNS topic
  insufficient_data_actions = ["${aws_sns_topic.luigi_slack.arn}"]
  ok_actions                = ["${aws_sns_topic.luigi_slack.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "other_alarm" {
  ...

  # Point to the Customer’s SNS topic
  alarm_actions = ["${aws_sns_topic.customer_slack.arn}"]
  ok_actions    = ["${aws_sns_topic.customer_slack.arn}"]

  ...
}
```

Variables
---------
_Variables marked with **[*]** are mandatory._

###### General variables
 - `name` - The name for resources created by this module. **[*]**
 - `sns_topic_arn` - The AWS ARN for the SNS topic to subscribe to. **[*]**
 - `slack_url` - The Slack webhook URL to send messages to. **[*]**
 - `tags` - List of tags to add to the Lambda function this module uses to send slack messages. [Default: `{}`]

###### OK state variables
 - `ok_user_name` - The username to use when sending `OK` type messages. [Default: _blank_]
 - `ok_user_emoji` - The icon for the user when sending `OK` type messages. [Default: _blank_]
 - `ok_status_emoji` - The emoji to use for `OK` type messages. [Default: `:white_check_mark:`]
 
###### ALARM state variables
 - `alarm_user_name` - The username to use when sending `ALARM` type messages. [Default: _blank_]
 - `alarm_user_emoji` - The icon for the user when sending `ALARM` type messages. [Default: _blank_]
 - `alarm_status_emoji` - The emoji to use for `ALARM` type messages. [Default: `:x:`]
 
###### INSUFFICIENT_DATA state variables
 - `insufficient_data_user_name` - The username to use when sending `INSUFFICIENT_DATA` type messages. [Default: _blank_]
 - `insufficient_data_user_emoji` - The icon for the user when sending `INSUFFICIENT_DATA` type messages. [Default: _blank_]
 - `insufficient_data_status_emoji` - The emoji to use for `INSUFFICIENT_DATA` type messages. [Default: `:x:`]

<br />

Outputs
-------
_None_