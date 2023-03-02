variable "account_ids" {
  type = map(string)
}

variable "cross_account_role_arns" {
  type = list(string)
}

variable "github_organisation" {
  default = "communitiesuk"
}

variable "region" {
  default = "eu-west-2"
}