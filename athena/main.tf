provider "aws" {
  region = var.region
}

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


terraform {
  backend "s3" {
    bucket         = "tdk-terraform-state.io"
    key            = "global/glue/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state"
    encrypt        = true
  }
}

module "glue" {
  source            = "../modules/glue"
  region            = var.region
  bucket_name       = var.bucket_name
  glue_catalog_name = var.glue_catalog_name
  glue_table_name   = var.glue_table_name
  glue_crawler_name = var.glue_crawler_name
}

module "redshift" {
  source             = "../modules/redshift"
  region             = var.region
  cluster_identifier = var.cluster_identifier
  database_name      = var.database_name
  database_username  = var.database_username
  database_password  = var.database_password
  client_ip_address  = var.client_ip_address
  vpc_id             = var.vpc_id
  glue_catalog_name  = var.glue_catalog_name
  bucket_name        = var.bucket_name
}

/*
// remote_state allows you to retrieve information about objects previously created in AWS
data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "tdk-terraform-state.io"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
  }
}
*/
