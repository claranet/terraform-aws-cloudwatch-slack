# Subscribe the Lambda function to the SNS topic.

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = "${var.sns_topic_arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.slack.arn}"
}

# Add permission for SNS to execute the Lambda function.

resource "aws_lambda_permission" "slack" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.slack.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${var.sns_topic_arn}"
}
