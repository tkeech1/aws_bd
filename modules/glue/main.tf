resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = var.glue_catalog_name
}

resource "aws_glue_crawler" "glue_crawler" {
  database_name = "${aws_glue_catalog_database.aws_glue_catalog_database.name}"
  name          = var.glue_crawler_name
  role          = "${aws_iam_role.glue_role.arn}"

  catalog_target {
    database_name = "${aws_glue_catalog_database.aws_glue_catalog_database.name}"
    tables = ["${aws_glue_catalog_table.order_data_table.name}"]
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "LOG"
  }

  configuration = <<EOF
{
  "Version":1.0,
    "CrawlerOutput": {
      "Partitions": { "AddOrUpdateBehavior": "InheritFromTable" }
    }
}
EOF
}

resource "aws_glue_catalog_table" "order_data_table" {
  name          = var.glue_table_name
  database_name = "${aws_glue_catalog_database.aws_glue_catalog_database.name}"

  partition_keys {
    name    = "year"
    type    = "string"
  }
  partition_keys {
    name    = "month"
    type    = "string"
  }
  partition_keys {
    name    = "day"
    type    = "string"
  }
  partition_keys {
    name    = "hour"
    type    = "string"
  }
  

  storage_descriptor {
    location      = "s3://${var.bucket_name}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "my-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"            = ","
      }
    }

    columns {
      name = "InvoiceNo"
      type = "string"
    }

    columns {
      name = "StockCode"
      type = "string"
    }

    columns {
      name = "Description"
      type = "string"
    }

    columns {
      name = "Quantity"
      type = "bigint"
    }

    columns {
      name = "InvoiceDate"
      type = "string"
    }

    columns {
      name = "UnitPrice"
      type = "double"
    }

    columns {
      name = "CustomerID"
      type = "bigint"
    }

    columns {
      name = "Country"
      type = "string"
    }

  }
}

# create an IAM role for glue
resource "aws_iam_role" "glue_role" {
  name               = "glue_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# glue iAM policy
resource "aws_iam_policy" "glue_policy" {
  name        = "glue_policy"
  path        = "/"
  description = "IAM policy for Glue"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "glue:*",
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListAllMyBuckets",
            "s3:GetBucketAcl",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeRouteTables",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",				
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "iam:ListRolePolicies",
            "iam:GetRole",
            "iam:GetRolePolicy",
            "cloudwatch:PutMetricData"                
        ],
        "Resource": [
            "*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:CreateBucket"
        ],
        "Resource": [
            "arn:aws:s3:::aws-glue-*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"				
        ],
        "Resource": [
            "arn:aws:s3:::aws-glue-*/*",
            "arn:aws:s3:::*/*aws-glue-*/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject"
        ],
        "Resource": [
            "arn:aws:s3:::crawler-public*",
            "arn:aws:s3:::aws-glue-*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:AssociateKmsKey"                
        ],
        "Resource": [
            "arn:aws:logs:*:*:/aws-glue/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ],
        "Condition": {
            "ForAllValues:StringEquals": {
                "aws:TagKeys": [
                    "aws-glue-service-resource"
                ]
            }
        },
        "Resource": [
            "arn:aws:ec2:*:*:network-interface/*",
            "arn:aws:ec2:*:*:security-group/*",
            "arn:aws:ec2:*:*:instance/*"
        ]
    },
    {
        "Sid": "",
        "Effect": "Allow",
        "Action": [
            "s3:ListBucket",
            "s3:*Object"
        ],
        "Resource": [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
    }
  ]
}
EOF
}

# attaches the policy to the role
resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
  role       = "${aws_iam_role.glue_role.name}"
  policy_arn = "${aws_iam_policy.glue_policy.arn}"
}