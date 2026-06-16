variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "albs" {
  type = map(string)
}

variable "target_groups" {
  type = map(string)
}

variable "us_region" {
  type    = string
  default = "us-east-1"
}

variable "cloudfront_distribution_ids" {
  type = object({
    auth          = object({ id = string, name = string })
    reg           = object({ id = string, name = string })
    toggles       = object({ id = string, name = string })
    frontend_0    = object({ id = string, name = string })
    frontend_1    = object({ id = string, name = string })
    data_frontend = object({ id = string, name = string })
    warehouse_api = object({ id = string, name = string })
  })
}
