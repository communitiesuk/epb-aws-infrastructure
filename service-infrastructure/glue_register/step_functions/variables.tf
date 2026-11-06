variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. epb-integration-domestic"
}

variable "glue_update_created_at_name" {
  type        = string
  description = "Name of the Glue job that updates the createdAt value of assessments."
}

variable "glue_update_status_name" {
  type        = string
  description = "Name of the Glue job that updates the cancelledAt value of assessments."
}

variable "glue_update_address_id_name" {
  type        = string
  description = "Name of the Glue job updates the address_id of assessments"
}

variable "glue_green_deals_name" {
  type        = string
  description = "Name of the Glue job that inserts green deals"
}
