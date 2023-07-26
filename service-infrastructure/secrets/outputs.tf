output "secret_arns" {
  value = { for k, v in var.secrets : k => aws_secretsmanager_secret.this[k].arn }
}


# I had to change the service-infrastructure\secrets\outputs.tf to
#output "secret_arns" {
#  value = {
#    RDS_AUTH_SERVICE_PASSWORD            = "1"
#    RDS_AUTH_SERVICE_USERNAME            = "1"
#    RDS_AUTH_SERVICE_CONNECTION_STRING   = "1"
#    RDS_API_SERVICE_USERNAME             = "1"
#    RDS_API_SERVICE_CONNECTION_STRING    = "1"
#    RDS_API_SERVICE_PASSWORD             = "1"
#    RDS_TOGGLES_PASSWORD                 = "1"
#    RDS_TOGGLES_USERNAME                 = "1"
#    RDS_TOGGLES_CONNECTION_STRING        = "1"
#    RDS_WAREHOUSE_CONNECTION_STRING      = "1"
#    RDS_WAREHOUSE_PASSWORD               = "1"
#    RDS_WAREHOUSE_USERNAME               = "1"
#    EPB_API_URL                          = "1"
#    EPB_AUTH_SERVER                      = "1"
#    EPB_QUEUES_URI                       = "1"
#    EPB_UNLEASH_URI                      = "1"
#    EPB_DATA_WAREHOUSE_QUEUES_URI        = "1"
#    EPB_WORKER_REDIS_URI                 = "1"
#    ODE_BUCKET_NAME                      = "1"
#    ODE_BUCKET_SECRET                    = "1"
#    ODE_BUCKET_ACCESS_KEY                = "1"
#    RDS_PGLOGICAL_TEST_USERNAME          = "1"
#    RDS_PGLOGICAL_TEST_PASSWORD          = "1"
#    RDS_PGLOGICAL_TEST_CONNECTION_STRING = "1"
#  }
#  #{ for k, v in var.secrets : k => aws_secretsmanager_secret.this[k].arn }
#}
