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

# create the IAM instance role for EC2
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


# create the IAM instance role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Policy to allow lambda to access Kinesis data stream
resource "aws_iam_role_policy" "lambda_kinesis_policy" {
  name   = "lambda_kinesis_policy"
  role   = "${aws_iam_role.lambda_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kinesis:Get*",
                "kinesis:List*",
                "kinesis:Describe*"
            ],
            "Resource": ["arn:aws:kinesis:${var.region}:${data.aws_caller_identity.current.account_id}:stream/${aws_kinesis_stream.CadabraOrders_s3_kinesis_data_stream.name}"]
        }
    ]
}
EOF
}

# policy to allow Lambda to access DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "lambda_dynamodb_policy"
  role   = "${aws_iam_role.lambda_role.id}"
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
                "dynamodb:DeleteItem",
                "dynamodb:BatchWriteItem"
            ],
            "Resource": "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.dynamodb_cadabra_orders_table.name}"
        }
    ]
}
EOF
}

# allows a lambda to log to CloudWatch
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# allows a service to access the Kinesis stream
resource "aws_iam_policy" "kinesis_policy" {
  name        = "kinesis_policy"
  path        = "/"
  description = "IAM policy for access to the Cadabra stream"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kinesis:Get*",
                "kinesis:List*",
                "kinesis:Describe*"
            ],
            "Resource": ["arn:aws:kinesis:${var.region}:${data.aws_caller_identity.current.account_id}:stream/${aws_kinesis_stream.CadabraOrders_s3_kinesis_data_stream.name}"]
        }
    ]
}
EOF
}

# attaches the logging policy to the lambda role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}


# create the IAM instance role for kinesis analytics
resource "aws_iam_role" "kinesisanalytics_role" {
  name               = "kinesisanalytics_role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "kinesisanalytics.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# attaches the kinesis stream policy to the kinesis analytics role
resource "aws_iam_role_policy_attachment" "kinesis_analytics_kinesis_stream" {
  role       = "${aws_iam_role.kinesisanalytics_role.name}"
  policy_arn = "${aws_iam_policy.kinesis_policy.arn}"
}
