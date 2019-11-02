# Policy to give permissions to write records to the firehose endpoint
resource "aws_iam_role_policy" "firehose_policy" {
  name   = "firehose_policy"
  role   = "${aws_iam_role.ec2role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ],
      "Effect": "Allow",
      "Resource": ["arn:aws:firehose:${var.region}:${data.aws_caller_identity.current.account_id}:deliverystream/${aws_kinesis_firehose_delivery_stream.PurchaseLogs_s3_firehose_stream.name}"]
    },
    { 
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"      
    }
  ]
}
EOF
}

# Policy to give permissions to write records to the kinesis data stream endpoint
resource "aws_iam_role_policy" "kinesis_datastream_policy" {
  name   = "kinesis_datastream_policy"
  role   = "${aws_iam_role.ec2role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kinesis:PutRecord",
        "kinesis:PutRecords",
        "kinesis:GetRecords",
        "kinesis:GetRecord"
      ],
      "Effect": "Allow",
      "Resource": ["arn:aws:kinesis:${var.region}:${data.aws_caller_identity.current.account_id}:stream/${aws_kinesis_stream.CadabraOrders_s3_kinesis_data_stream.name}"]
    }
  ]
}
EOF
}

# Policy to give permissions to write records to the kinesis data stream endpoint
resource "aws_iam_role_policy" "dynamodb_policy" {
  name   = "dynamodb_policy"
  role   = "${aws_iam_role.ec2role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.dynamodb_cadabra_orders_table.name}"
        }
    ]
}
EOF
}









# create the IAM instance role
resource "aws_iam_role" "ec2role" {
  name               = "ec2_role"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
