variable "prefix" {
  type = string
}

variable "athena_workgroup_arn" {
  type = string
}

variable "glue_s3_bucket_read_policy_arn" {
  type = string
}

variable "output_bucket_write_policy_arn" {
  type = string
}

variable "glue_catalog_name" {
  type = string
}