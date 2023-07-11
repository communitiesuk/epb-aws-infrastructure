variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "bucket_name" {
  default = "epbr-tech-docs-repo"
  type    = string
}

variable "index_document" {
  default = "index.html"
  type    = string
}

variable "ci_account_id" {
  type = string
}
