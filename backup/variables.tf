variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "account_ids" {
  type = map(string)
}