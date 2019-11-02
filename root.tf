variable "dynamodb_cadabra_orders_table_name" {
  type = string
}
variable "dynamodb_cadabra_orders_partition_key" {
  type = string
}
variable "dynamodb_cadabra_orders_sort_key" {
  type = string
}
variable "region" {
  type = string
}
variable "public_key_name" {
  type = string
}
variable "public_key_value" {
  type = string
}
variable "aws_access_key_id" {
  type = string
}
variable "aws_secret_access_key" {
  type = string
}
variable "bucket_name" {
  type = string
}
variable "kinesis_firehose_name" {
  type = string
}
variable "firehose_buffer_interval" {
  type = number
}
variable "kinesis_datastream_name" {
  type = string
}
data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}
