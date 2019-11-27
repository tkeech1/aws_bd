resource "aws_redshift_cluster" "redshift" {
  cluster_identifier = var.cluster_identifier
  database_name      = var.database_name
  master_username    = var.database_username
  master_password    = var.database_password
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  enhanced_vpc_routing = "false"
  skip_final_snapshot = "true"
  iam_roles = ["${aws_iam_role.redshift_role.arn}"]
}

// create a security group to allow access to the cluster
resource "aws_security_group" "redshift_security" {
  name        = "redshift_security"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    # these ports should be locked down
    from_port = 0
    to_port   = 22
    protocol  = "tcp"

    # we do not recommend opening your cluster to 0.0.0.0/0
    # use the following format "1.1.1.1/32"
    cidr_blocks = ["${var.client_ip_address}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = ["ingress", "egress"]
  }

}

resource "aws_security_group_rule" "redshift_port_rule" {
  type            = "ingress"
  from_port       = 0
  to_port         = 5439
  protocol        = "tcp"
  # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
  cidr_blocks = ["${var.client_ip_address}/32"]

  security_group_id = "${aws_security_group.redshift_security.id}"
}

# create an IAM role for redshift
resource "aws_iam_role" "redshift_role" {
  name               = "redshift_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { 
        "Service": "redshift.amazonaws.com" 
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# redshift iAM policy
resource "aws_iam_policy" "redshift_policy" {
  name        = "redshift_policy"
  path        = "/"
  description = "IAM policy for Redshift"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListMultipartUploadParts",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket_name}",
                "arn:aws:s3:::${var.bucket_name}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "glue:CreateDatabase",
                "glue:DeleteDatabase",
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:UpdateDatabase",
                "glue:CreateTable",
                "glue:DeleteTable",
                "glue:BatchDeleteTable",
                "glue:UpdateTable",
                "glue:GetTable",
                "glue:GetTables",
                "glue:BatchCreatePartition",
                "glue:CreatePartition",
                "glue:DeletePartition",
                "glue:BatchDeletePartition",
                "glue:UpdatePartition",
                "glue:GetPartition",
                "glue:GetPartitions",
                "glue:BatchGetPartition"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

# attaches the policy to the role
resource "aws_iam_role_policy_attachment" "redshift_policy_attachment" {
  role       = "${aws_iam_role.redshift_role.name}"
  policy_arn = "${aws_iam_policy.redshift_policy.arn}"
}