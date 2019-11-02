resource "aws_dynamodb_table" "dynamodb_cadabra_orders_table" {
  name           = var.dynamodb_cadabra_orders_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = var.dynamodb_cadabra_orders_partition_key
  range_key      = var.dynamodb_cadabra_orders_sort_key

  attribute {
    name = var.dynamodb_cadabra_orders_partition_key
    type = "N"
  }

  attribute {
    name = var.dynamodb_cadabra_orders_sort_key
    type = "S"
  }

  /*ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  global_secondary_index {
    name               = "GameTitleIndex"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }*/
}
