# Create the Lambda function.

module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda?ref=v0.9.1"

  function_name = "${var.name}"
  description   = "Sends CloudWatch Alarm events to Slack"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.6"
  timeout       = 10

  tags = "${var.tags}"

  source_path = "${path.module}/lambda.py"

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.lambda.json}"

  environment {
    variables = {
      SLACK_URL = "${var.slack_url}"

      OK_USER_NAME    = "${var.ok_user_name}"
      OK_USER_EMOJI   = "${var.ok_user_emoji}"
      OK_STATUS_EMOJI = "${var.ok_status_emoji}"

      ALARM_USER_NAME    = "${var.alarm_user_name}"
      ALARM_USER_EMOJI   = "${var.alarm_user_emoji}"
      ALARM_STATUS_EMOJI = "${var.alarm_status_emoji}"

      INSUFFICIENT_DATA_USER_NAME    = "${var.insufficient_data_user_name}"
      INSUFFICIENT_DATA_USER_EMOJI   = "${var.insufficient_data_user_emoji}"
      INSUFFICIENT_DATA_STATUS_EMOJI = "${var.insufficient_data_status_emoji}"
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarmHistory",
    ]

    resources = [
      "*",
    ]
  }
}

# Subscribe the Lambda function to the SNS topic.

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = "${var.sns_topic_arn}"
  protocol  = "lambda"
  endpoint  = "${module.lambda.function_arn}"
}

# Add permission for SNS to execute the Lambda function.

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${module.lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${var.sns_topic_arn}"
}
