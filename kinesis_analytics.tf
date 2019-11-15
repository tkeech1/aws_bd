resource "aws_kinesis_analytics_application" "OrderRateAlarms" {
  name = var.kinesis_analytics_application_name

  inputs {
    name_prefix = "test_prefix"

    kinesis_stream {
      resource_arn = "${aws_kinesis_stream.CadabraOrders_s3_kinesis_data_stream.arn}"
      role_arn     = "${aws_iam_role.kinesisanalytics_role.arn}"
    }

    parallelism {
      count = 1
    }

    schema {
      record_columns {
        name     = "Description"
        sql_type = "VARCHAR(64)"
      }

      record_encoding = "UTF-8"

      record_format {
        mapping_parameters {
          csv {
            record_column_delimiter = ","
            record_row_delimiter    = "\n"
          }
        }
      }
    }
  }
}