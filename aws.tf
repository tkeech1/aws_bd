provider "aws" {
  region     = "us-east-1"
}

# create an S3 bucket
resource "aws_s3_bucket" "bd" {
  bucket = "tdk-bd.io"
  acl    = "private"
  force_destroy = true
}

# create an IAM role to allow firehose to access the S3 bucket
resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"
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

# create permissions to allow ec2 access to firehose
resource "aws_iam_role_policy" "s3_policy" {
  name = "s3_policy"
  role = "${aws_iam_role.firehose_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# create the kinesis firehose
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "PurchaseLogs"
  destination = "extended_s3"
  extended_s3_configuration {
    role_arn   = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${aws_s3_bucket.bd.arn}"
    buffer_interval = 60
  }
}

# create the public key to connect to the ec2 instance
resource "aws_key_pair" "ec2-key" {
  key_name   = "ec2-key-tk"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9E7yCIHpNKaHXtzxFnKJPT+gtyXAnprq/pCfs/fPW+sXwAAFVsIt0rzEghkSshR8lUcyGJTafOFLPIAfSHirp2JdREtWa3CijokSHzaoSk2PrB8KzrX07l998lYGVgKzsOb8TmeLAeHR/vgwQ0r7r/17JOIRLrYcaghkrpwDt/GPVCxZa8TjQWiyX9Aw+QRP4IX6N65py5y2dsh7+GOS/rIlueRDx7YVEhzA8OvhiN2v0EW8QtdHhWU6uEOpuPF16sXYTImb73BnsjE+CZWrkjAlIp35hbuw1E2jZWAWnA10txc5VadjemPsPysCBMkEBYDl/DAdFQ0YlB5G3DKBD todd@tk"
}

# create an IAM instance profile to attach to the ec2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = "${aws_iam_role.ec2role.name}"
}

# create the IAM instance role
resource "aws_iam_role" "ec2role" {
  name = "ec2_role"
  path = "/"
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

# create permissions to allow ec2 access to firehose
resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_policy"
  role = "${aws_iam_role.ec2role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "firehose:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# create an ec2 instance
resource "aws_instance" "ec2inst" {
  ami           = "ami-00eb20669e0990cb4"
  instance_type = "t2.nano"
  key_name      = "ec2-key-tk"
  iam_instance_profile = "ec2_profile"
  user_data     = <<EOF
		#! /bin/bash
    sudo yum install -y aws-kinesis-agent
    wget http://media.sundog-soft.com/AWSBigData/LogGenerator.zip
    unzip LogGenerator.zip
    chmod a+x LogGenerator.py
    sudo mkdir /var/log/cadabra
    # this endpoint doesn't work for some reason - leaving it blank works
    #sudo sed -i -e 's/"firehose.endpoint": "",/"firehose.endpoint": "firehose.us-east1.amazonaws.com",/g' /etc/aws-kinesis/agent.json
    sudo sed -i '7,11d' /etc/aws-kinesis/agent.json
    sudo sed -i -e 's/\/tmp\/app.log*/\/var\/log\/cadabra\/*.log/g' /etc/aws-kinesis/agent.json
    sudo sed -i -e 's/yourdeliverystream/PurchaseLogs/g' /etc/aws-kinesis/agent.json
    sudo service aws-kinesis-agent start
    sudo chkconfig aws-kinesis-agent on
    sleep 120
    cd / && sudo python LogGenerator.py 500
	EOF
}