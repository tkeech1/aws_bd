variable "region" {
  type = string
}
variable "cluster_identifier" {
  type = string
}
variable "database_username" {
  type = string
}
variable "database_password" {
  type = string
}
variable "database_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "client_ip_address" {
  type = string
}
variable "glue_catalog_name" {
  type = string
}
variable "bucket_name" {
  type = string
}

data "aws_caller_identity" "current" {}
