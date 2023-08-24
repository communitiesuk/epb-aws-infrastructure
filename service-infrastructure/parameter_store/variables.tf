variable "parameters" {
  type = map(object({
    type  = string
    value = string
    tier  = optional(string, "Standard")
  }))
  description = "map of parameter names to type and value"
}

