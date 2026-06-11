variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "name" {
  type    = string
  default = "bastion"
}

variable "tag" {
  type    = string
  default = "bastion-host"
}

