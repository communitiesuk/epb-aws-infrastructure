variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "ecr_arns" {
  type    = list(string)
  default = null
}

variable "codestar_connection_arn" {
  type    = string
  default = ""

}

variable "codebuild_names" {
  type = list(string)
}

