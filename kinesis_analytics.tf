resource "aws_kinesis_analytics_application" "OrderRateAlarms" {
  name = var.kinesis_analytics_application_name
  code = file("./analytics-query.txt")

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
        mapping  = "$.Description"
        name     = "Description"
        sql_type = "VARCHAR(64)"
      }

      record_columns {
        mapping  = "$.StockCode"
        name     = "StockCode"
        sql_type = "VARCHAR(10)"
      }

      record_columns {
        mapping  = "$.InvoiceNo"
        name     = "InvoiceNo"
        sql_type = "INTEGER"
      }

      record_columns {
        mapping  = "$.InvoiceDate"
        name     = "InvoiceDate"
        sql_type = "VARCHAR(32)"
      }

      record_columns {
        mapping  = "$.Quantity"
        name     = "Quantity"
        sql_type = "INTEGER"
      }

      record_columns {
        mapping  = "$.UnitPrice"
        name     = "UnitPrice"
        sql_type = "DECIMAL"
      }

      record_columns {
        mapping  = "$.Country"
        name     = "Country"
        sql_type = "VARCHAR(64)"
      }

      record_columns {
        mapping  = "$.Customer"
        name     = "Customer"
        sql_type = "VARCHAR(64)"
      }

      record_encoding = "UTF-8"

      record_format {
        mapping_parameters {
          json {
            record_row_path = "$"
          }
        }
      }
    }
  }

  outputs {
    name = "TRIGGER_COUNT_STREAM"
    kinesis_stream {
      resource_arn = "${aws_kinesis_stream.OrderRateAlarms_kinesis_data_stream.arn}"
      role_arn     = "${aws_iam_role.kinesisanalytics_role.arn}"
    }

    schema {
      record_format_type = "JSON"
    }
  }
}