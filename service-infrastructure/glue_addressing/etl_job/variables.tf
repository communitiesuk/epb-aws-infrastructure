variable "job_name" {
  type        = string
  description = "the ETL job name"
}

variable "script_file_name" {
  type        = string
  description = "the name of python script file"
}


variable "scripts_module" {
  type        = string
  description = "the path to etl scripts"
}

variable "role_arn" {
  type        = string
  description = "the arn of the glue IAM role"
}

variable "bucket_name" {
  type        = string
  description = "the name of the glue bucket"
}

variable "glue_connector" {
  type        = list(string)
  description = "the name of the glue db connector"
  default     = []
}

variable "arguments" {
  type        = map(string)
  description = "map of arguments passed to the ETL job script"
}

variable "python_version" {
  type    = string
  default = "3"
}

variable "glue_version" {
  type    = string
  default = "5.0"
}

variable "suffix" {
  type    = string
  default = ""
}
