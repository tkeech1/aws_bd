# create an S3 bucket
resource "aws_s3_bucket" "firehose_destination_bucket" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "firehose_elasticsearch_destination_bucket" {
  bucket        = "tdk-bd-es.io"
  acl           = "private"
  force_destroy = true
}

# create an IAM role to allow firehose to access the S3 bucket
resource "aws_iam_role" "firehose_s3_role" {
  name               = "firehose_s3_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# create permissions to allow firehose to read/write and list objects in the S3 bucket
resource "aws_iam_role_policy" "firehose_s3_role_policy" {
  name   = "firehose_s3_role_policy"
  role   = "${aws_iam_role.firehose_s3_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [    
    {
        "Sid": "",
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.firehose_destination_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.firehose_elasticsearch_destination_bucket.bucket}"
        ]
    },
    {
        "Sid": "",
        "Effect": "Allow",
        "Action": "s3:*Object",
        "Resource": ["arn:aws:s3:::${aws_s3_bucket.firehose_destination_bucket.bucket}/*"]
    },
    {
        "Sid": "",
        "Effect": "Allow",
        "Action": "es:*",
        "Resource": [
          "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_elasticsearch_domain.es[0].domain_name}",
          "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_elasticsearch_domain.es[0].domain_name}/*"]
    },
        {
        "Sid": "",
        "Effect": "Allow",
        "Action": "lambda:*",
        "Resource": ["*"]
    }
  ]
}
EOF
}

# create the kinesis firehose
resource "aws_kinesis_firehose_delivery_stream" "PurchaseLogs_s3_firehose_stream" {
  name        = var.kinesis_firehose_name
  destination = "extended_s3"
  extended_s3_configuration {
    role_arn        = "${aws_iam_role.firehose_s3_role.arn}"
    bucket_arn      = "${aws_s3_bucket.firehose_destination_bucket.arn}"
    buffer_interval = var.firehose_buffer_interval
  }
}

# create the kinesis firehose for writing to elastic search
resource "aws_kinesis_firehose_delivery_stream" "weblogs_firehose_stream" {
  name        = var.kinesis_firehose_weblogs_name
  destination = "elasticsearch"
  s3_configuration {
    role_arn           = "${aws_iam_role.firehose_s3_role.arn}"
    bucket_arn         = "${aws_s3_bucket.firehose_elasticsearch_destination_bucket.arn}"
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }
  elasticsearch_configuration {
    domain_arn = "${aws_elasticsearch_domain.es[0].arn}"
    role_arn   = "${aws_iam_role.firehose_s3_role.arn}"
    index_name = var.kinesis_firehose_weblogs_name
    type_name  = var.kinesis_firehose_weblogs_name
    processing_configuration {
      enabled = "true"
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_weblogs_processor.arn}:$LATEST"
        }
      }
    }
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${aws_cloudwatch_log_group.weblog_firehose_processor_log.name}"
      log_stream_name = "weblogs_firehose_stream"
    }
  }
}

resource "aws_cloudwatch_log_group" "weblog_firehose_processor_log" {
  name              = "/aws/firehose/weblog"
  retention_in_days = 14
}

resource "aws_kinesis_stream" "CadabraOrders_s3_kinesis_data_stream" {
  name        = var.kinesis_datastream_name
  shard_count = 1
}

resource "aws_kinesis_stream" "OrderRateAlarms_kinesis_data_stream" {
  name        = var.kinesis_alarm_datastream_name
  shard_count = 1
}
