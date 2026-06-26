
resource "aws_db_parameter_group" "rds_instance" {
  name        = "aurora-${var.group_name}-instance-pg-${local.pg_major_version}"
  family      = "aurora-postgresql${local.pg_major_version}"
  description = "Aurora PG${local.pg_major_version} instance parameter group"

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_rds_cluster_parameter_group" "rds_cluster" {
  name        = "aurora-${var.group_name}-pg-${local.pg_major_version}"
  family      = "aurora-postgresql${local.pg_major_version}"
  description = "Aurora PG${local.pg_major_version} cluster parameter group"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_wal_senders"
    value        = "10"
    apply_method = "pending-reboot"
  }

  #  Should exceed the expected number of subscription connections, plus additional capacity for table synchronization. Configure this above your total database count.
  parameter {
    name         = "max_logical_replication_workers"
    value        = "12"
    apply_method = "pending-reboot"
  }

  # Defines the system's maximum supported background processes. Set this slightly above max_replication_slots.
  parameter {
    name         = "max_worker_processes"
    value        = "15"
    apply_method = "pending-reboot"
  }

  # Determines the system's maximum background process capacity. Configure this to at least max_logical_replication_worker + 1 or higher.
  parameter {
    name         = "max_replication_slots"
    value        = "10"
    apply_method = "pending-reboot"
  }


  lifecycle {
    ignore_changes        = [description]
    create_before_destroy = true
  }


}


