variable "parameters" {
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
}