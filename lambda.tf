# create a lambda
resource "aws_lambda_function" "kinesis_processor" {
  filename      = "function.zip"
  function_name = var.lambda_kinesis_processor_name
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "lambda-function.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("function.zip")}"

  runtime    = "python2.7"
  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.kinesis_processor_log"]
}

# trigger the lamba off updates to the kinesis stream
resource "aws_lambda_event_source_mapping" "kinesis_lambda_trigger" {
  event_source_arn  = "${aws_kinesis_stream.CadabraOrders_s3_kinesis_data_stream.arn}"
  function_name     = "${aws_lambda_function.kinesis_processor.arn}"
  starting_position = "LATEST"
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "kinesis_processor_log" {
  name              = "/aws/lambda/${var.lambda_kinesis_processor_name}"
  retention_in_days = 14
}

# create a lambda
resource "aws_lambda_function" "transaction_rate_alarm" {
  filename      = "function-sns.zip"
  function_name = var.lambda_kinesis_sns_processor_name
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "lambda-sns.lambda_handler"
  environment {
    variables = {
      sns_topic = "${aws_sns_topic.CadabraAlarms.arn}"
    }
  }

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("function-sns.zip")}"

  runtime    = "python2.7"
  timeout    = "60"
  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.kinesis_processor_log"]
}

# trigger the lamba off updates to the kinesis stream
resource "aws_lambda_event_source_mapping" "kinesis_alarm_lambda_trigger" {
  event_source_arn  = "${aws_kinesis_stream.OrderRateAlarms_kinesis_data_stream.arn}"
  function_name     = "${aws_lambda_function.transaction_rate_alarm.arn}"
  starting_position = "LATEST"
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "kinesis_sns_processor_log" {
  name              = "/aws/lambda/${var.lambda_kinesis_sns_processor_name}"
  retention_in_days = 14
}


# create a lambda for weblogs processing
resource "aws_lambda_function" "lambda_weblogs_processor" {
  filename      = "function-weblog.zip"
  function_name = var.lambda_weblogs_processor_name
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "lambda_log_transform.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("function-weblog.zip")}"

  runtime    = "nodejs10.x"
  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.kinesis_processor_log"]
}