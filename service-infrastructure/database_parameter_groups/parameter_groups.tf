resource "aws_db_parameter_group" "rds_db" {
  count  = var.has_rds == true ? 1 : 0
  name   = "rds-pg"
  family = "postgres14"
}

resource "aws_rds_cluster_parameter_group" "rds_aurora" {
  name   = var.aurora_name
  family = "aurora-postgresql14"


}

resource "aws_rds_cluster_parameter_group" "rds_aurora_serverless" {
  name   = "${var.aurora_name}-serverless"
  family = "aurora-postgresql14"

  # required for blue/green deployment
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
}

resource "aws_rds_cluster_parameter_group" "rds_aurora_serverless_17" {
  name   = "${var.aurora_name}-serverless-17"
  family = "aurora-postgresql17"

  # required for blue/green deployment using logical replication
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
}

