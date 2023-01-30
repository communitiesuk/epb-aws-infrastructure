terraform {
  required_providers {
    aws = {
      version = "~>4.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = "eu-west-2"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}

resource "aws_s3_bucket" "epbr_s3_terraform_state" {
  bucket        = "epbr-integration-terraform-state"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket              = aws_s3_bucket.epbr_s3_terraform_state.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_dynamodb_table" "epbr_dynamo_terraform_state" {
  name           = "epbr-terraform-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}