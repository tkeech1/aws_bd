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



resource "aws_kinesis_stream" "CadabraOrders_s3_kinesis_data_stream" {
  name        = var.kinesis_datastream_name
  shard_count = 1
}

resource "aws_kinesis_stream" "OrderRateAlarms_kinesis_data_stream" {
  name        = var.kinesis_alarm_datastream_name
  shard_count = 1
}
