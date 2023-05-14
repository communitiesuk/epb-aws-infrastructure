resource "aws_db_parameter_group" "target" {
  name   = "rds-pglogical-target-pg"
  family = "postgres14"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pglogical"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster_parameter_group" "target" {
  name   = "aurora-pglogical-target-pg"
  family = "aurora-postgresql14"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pglogical"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_parameter_group" "source" {
  name   = "rds-pglogical-source-pg"
  family = "postgres14"

  parameter {
    name         = "rds.logical_replication"
    value        = 1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_worker_processes"
    value        = 10
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_replication_slots"
    value        = 10
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_wal_senders"
    value        = 10
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pglogical"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster_parameter_group" "source" {
  name   = "aurora-pglogical-source-pg"
  family = "postgres14"

  parameter {
    name         = "max_worker_processes"
    value        = 10
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_wal_senders"
    value        = 10
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pglogical"
    apply_method = "pending-reboot"
  }
}
