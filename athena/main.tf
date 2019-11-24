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
  source = "../modules/glue"
  region = var.region
  bucket_name = var.bucket_name
  glue_catalog_name = var.glue_catalog_name
  glue_table_name = var.glue_table_name
  glue_crawler_name = var.glue_crawler_name
}

/*
data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "tdk-terraform-state.io"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
  }
}
*/
