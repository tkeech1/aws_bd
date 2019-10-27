variable "region" {
  type = string
}
variable "bucket_name" {
  type = string
}
variable "kinesis_firehose_name" {
  type = string
}
variable "public_key_name" {
  type = string
}
variable "public_key_value" {
  type = string
}
variable "firehose_buffer_interval" {
  type = number
}
variable "kinesis_datastream_name" {
  type = string
}
data "aws_caller_identity" "current" {}

# ---

provider "aws" {
  region = var.region
}

# create an S3 bucket
resource "aws_s3_bucket" "firehose_destination_bucket" {
  bucket        = var.bucket_name
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
        "Sid": "ListObjectsInBucket",
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": ["arn:aws:s3:::${aws_s3_bucket.firehose_destination_bucket.bucket}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object",
        "Resource": ["arn:aws:s3:::${aws_s3_bucket.firehose_destination_bucket.bucket}/*"]
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

# create the public key to connect to the ec2 instance
resource "aws_key_pair" "ec2_public_key" {
  key_name   = var.public_key_name
  public_key = var.public_key_value
}

# create an IAM instance profile to attach to the ec2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = "${aws_iam_role.ec2role.name}"
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
        "kinesis:PutRecords"
      ],
      "Effect": "Allow",
      "Resource": ["arn:aws:kinesis:${var.region}:${data.aws_caller_identity.current.account_id}:stream/${aws_kinesis_stream.CadabraOrders_s3_kinesis_data_stream.name}"]
    }
  ]
}
EOF
}

# create an ec2 instance
resource "aws_spot_instance_request" "ec2_spot_inst" {
  ami                  = "ami-00eb20669e0990cb4"
  instance_type        = "t3.nano"
  spot_price           = "0.0025"
  spot_type            = "one-time"
  availability_zone    = "us-east-1c"
  key_name             = "ec2-key-tk"
  iam_instance_profile = "ec2_profile"
  depends_on           = [aws_kinesis_firehose_delivery_stream.PurchaseLogs_s3_firehose_stream]
  # Copies the myapp.conf file to /etc/myapp.conf
  user_data = <<EOF
		#! /bin/bash
    sudo yum install -y aws-kinesis-agent
    wget http://media.sundog-soft.com/AWSBigData/LogGenerator.zip
    unzip LogGenerator.zip
    chmod a+x LogGenerator.py
    sudo mkdir /var/log/cadabra
    # remove the Kinesis Data Streams configuration
    sudo sed -i '7,11d' /etc/aws-kinesis/agent.json
    # add the configuration for kinesis
    sed -i '7i{"filePattern": "/var/log/cadabra/*.log","kinesisStream": "CadabraOrders","partitionKeyOption": "RANDOM","dataProcessingOptions": [ { "optionName": "CSVTOJSON", "customFieldNames": ["InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate", "UnitPrice", "Customer", "Country"] } ]  },' /etc/aws-kinesis/agent.json 
    # set up the cadabra log directory
    sudo sed -i -e 's/\/tmp\/app.log*/\/var\/log\/cadabra\/*.log/g' /etc/aws-kinesis/agent.json
    # configure the Kinesis Firehose target
    sudo sed -i -e 's/yourdeliverystream/PurchaseLogs/g' /etc/aws-kinesis/agent.json
    # enable the Kinesis agent then set it to auto-start
    sudo service aws-kinesis-agent start
    sudo chkconfig aws-kinesis-agent on
    sleep 60
    cd / && sudo python LogGenerator.py 500
EOF
}
