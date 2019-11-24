variable "region" {
  type = string
}
variable "bucket_name" {
  type = string
}
variable "glue_catalog_name" {
  type = string
}
variable "glue_table_name" {
  type = string
}
variable "glue_crawler_name" {
  type = string
}

data "aws_caller_identity" "current" {}
