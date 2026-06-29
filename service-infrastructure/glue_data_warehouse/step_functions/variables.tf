variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. epb-integration"
}

variable "region" {
  type = string
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster running scheduled tasks."
}

variable "ecs_task_definition_arn" {
  type        = string
  description = "ARN of the ECS exec-cmd task definition."
}

variable "ecs_container_name" {
  type        = string
  description = "Name of the container in the task definition where the rake command runs."
}

variable "ecs_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ECS task networking."
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security group ID for the ECS task."
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ARN of the ECS task role (permissions the task itself has)."
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ARN of the ECS task execution role (permissions to pull images, logs, secrets)."
}

variable "ecs_rake_command" {
  type        = list(string)
  description = "Default command override sent to the ECS container for the refresh step."
  default     = ["bundle", "exec", "rake", "refresh_materialized_view"]
}

variable "ecs_materialized_view_name" {
  type        = string
  description = "Materialized view name to refresh. This is passed to the rake command as the NAME environment variable."
}

variable "glue_populate_job_name" {
  type        = string
  description = "Name of the Glue job that populates the catalog using the materialized view."
}

variable "glue_delete_job_name" {
  type        = string
  description = "Name of the Glue job that removes cancellations and opt-outs"
}

variable "glue_zip_export_job_name" {
  type        = string
  description = "Name of the Glue job that exports the catalog to CSVs in a zip file"
}