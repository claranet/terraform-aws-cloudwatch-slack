# Create the Lambda function.

data "archive_file" "slack" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = ".terraform/tf-aws-sns-lambda-slack/lambda.zip"
}

resource "aws_lambda_function" "slack" {
  function_name    = "${var.name}"
  description      = "Sends CloudWatch Alarm events to Slack"
  filename         = "${data.archive_file.slack.output_path}"
  source_code_hash = "${data.archive_file.slack.output_base64sha256}"
  role             = "${aws_iam_role.slack.arn}"
  handler          = "lambda.lambda_handler"
  runtime          = "python3.6"
  timeout          = 10

  tags = "${var.tags}"

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

# Add permission for Lambda to run the function.

data "aws_iam_policy_document" "slack_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "slack" {
  name               = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.slack_assume_role.json}"
}

# Add permission for Lambda to log to CloudWatch.

data "aws_iam_policy_document" "slack_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.slack.function_name}:*",
    ]
  }
}

resource "aws_iam_policy" "slack" {
  name   = "${var.name}"
  policy = "${data.aws_iam_policy_document.slack_logs.json}"
}

resource "aws_iam_policy_attachment" "slack" {
  name       = "${var.name}"
  roles      = ["${aws_iam_role.slack.name}"]
  policy_arn = "${aws_iam_policy.slack.arn}"
}
