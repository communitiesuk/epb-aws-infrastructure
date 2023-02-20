variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "secrets" {
  type        = map(string)
  description = "A map of secrets to create. The key is the name of the secret (prepended with environment prefix), the value is the secret value."
}