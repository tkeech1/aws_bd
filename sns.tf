resource "aws_sns_topic" "CadabraAlarms" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = "${aws_sns_topic.CadabraAlarms.arn}"
  protocol  = "sms"
  endpoint  = var.cell_phone_number
}