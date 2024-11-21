variable "ci_account_id" {
  type = string
}

variable "login_credentials_hash" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "parameters" {
  description = "A map of parameter values. Keys should be a subset of the ones passed to 'parameters' module."
  type        = map(string)
  sensitive   = true
}

variable "region" {
  default = "eu-west-2"
  type    = string
}
