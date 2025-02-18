variable "has_md_5_password" {
  type    = bool
  default = false
}

variable "aurora_name" {
  type    = string
  default = "aurora-pg"
}


variable "has_rds" {
  type    = bool
  default = true
}