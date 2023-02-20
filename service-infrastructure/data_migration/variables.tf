variable "prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "rds_db_connection_string_secret_arn" {
  type = string
}

variable "backup_file" {
  type = string
}

variable "rds_full_access_policy_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "backup_bucket_name" {
  type = string
}

variable "backup_bucket_arn" {
  type = string
}

variable "log_group" {
  type = string
}