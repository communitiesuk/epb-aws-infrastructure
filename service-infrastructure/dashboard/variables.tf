variable "environment" {
  type = string
}

variable "albs" {
  type = map(string)
}

variable "target_groups" {
  type = map(string)
}

variable "cloudfront_distribution_ids" {
  type = object({
    auth       = object({ id = string, name = string })
    reg        = object({ id = string, name = string })
    toggles    = object({ id = string, name = string })
    frontend_0 = object({ id = string, name = string })
    frontend_1 = object({ id = string, name = string })
  })
}