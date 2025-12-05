variable "prefix" {
  type = string
}

variable "oai_iam_arns" {
  type = list(string)
}

variable "allowed_origins" {
  type = list(string)
}