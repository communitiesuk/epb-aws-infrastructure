variable "name" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

variable "codebuild_environment_type" {
  default = "LINUX_CONTAINER"
  type    = string
}

variable "build_image_uri" {
  type = string
}

variable "buildspec_file" {
  type = string
}

variable "environment_variables" {
  type = list(map(string))
}

variable "region" {
  type = string
}
