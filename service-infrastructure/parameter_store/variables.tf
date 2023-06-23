variable "parameters" {
  type = map(object({
    type  = string
    value = string
  }))
  description = "map of parameter names to type and value"
}

