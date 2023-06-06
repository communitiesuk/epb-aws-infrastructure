variable "environment" {
  type = string
}

variable "prefix" {
  type = string
}

variable "forbidden_ip_addresses" {
  type = list(string)
}

variable "forbidden_ipv6_addresses" {
  type = list(string)
}
