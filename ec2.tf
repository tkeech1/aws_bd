# create an IAM instance profile to attach to the ec2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = "${aws_iam_role.ec2role.name}"
}

# create the public key to connect to the ec2 instance
resource "aws_key_pair" "ec2_public_key" {
  key_name   = var.public_key_name
  public_key = var.public_key_value
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
  user_data            = templatefile("user_data.tmpl", { aws_access_key_id = var.aws_access_key_id, aws_secret_access_key = var.aws_secret_access_key, aws_region = var.region })
}
