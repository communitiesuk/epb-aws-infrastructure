resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls_metric" {
  name = "unauthorized_api_calls_metric"

  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.errorCode = UnauthorizedOperation) ||
    ($.errorCode = AccessDenied) }
  EOT

  metric_transformation {
    name      = "unauthorized_api_calls_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "no_mfa_console_signin_metric" {
  name = "no_mfa_console_signin_metric"

  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventName = "ConsoleLogin") &&
    ($.additionalEventData.MFAUsed != "Yes") &&
    ($.userIdentity.type = "IAMUser") &&
    ($.responseElements.ConsoleLogin = "Success") }
  EOT

  metric_transformation {
    name      = "no_mfa_console_signin_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "root_account_login_metric" {
  name           = "root_account_login_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.userIdentity.type = Root) &&
    ($.userIdentity.invokedBy NOT EXISTS) &&
    ($.eventType != AwsServiceEvent)}
    EOT

  metric_transformation {
    name      = "root_account_login_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes_metric" {
  name           = "iam_policy_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventName = DeleteGroupPolicy) ||
    ($.eventName = DeleteRolePolicy) || 
    ($.eventName = DeleteUserPolicy) ||
    ($.eventName = PutGroupPolicy) ||
    ($.eventName = PutRolePolicy) ||
    ($.eventName = PutUserPolicy) ||
    ($.eventName = CreatePolicy) ||
    ($.eventName = DeletePolicy) ||
    ($.eventName = CreatePolicyVersion) ||
    ($.eventName = DeletePolicyVersion) ||
    ($.eventName = AttachRolePolicy) ||
    ($.eventName = DetachRolePolicy) ||
    ($.eventName = AttachUserPolicy) ||
    ($.eventName = DetachUserPolicy) ||
    ($.eventName = AttachGroupPolicy)||
    ($.eventName = DetachGroupPolicy)}
  EOT

  metric_transformation {
    name      = "iam_policy_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_config_changes_metric" {
  name           = "cloudtrail_config_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventName = CreateTrail) ||
    ($.eventName = UpdateTrail) ||
    ($.eventName = DeleteTrail) ||
    ($.eventName = StartLogging) ||
    ($.eventName = StopLogging)}
    EOT

  metric_transformation {
    name      = "cloudtrail_config_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes_metric" {
  name           = "s3_bucket_policy_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventSource = s3.amazonaws.com) &&
    (($.eventName = PutBucketAcl) ||
      ($.eventName = PutBucketPolicy) ||
      ($.eventName = PutBucketCors) ||
      ($.eventName = PutBucketLifecycle) ||
      ($.eventName = PutBucketReplication) ||
      ($.eventName = DeleteBucketPolicy) ||
      ($.eventName = DeleteBucketCors) ||
      ($.eventName = DeleteBucketLifecycle) ||
      ($.eventName = DeleteBucketReplication))}
  EOT

  metric_transformation {
    name      = "s3_bucket_policy_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes_metric" {
  name           = "network_gateway_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventName = CreateCustomerGateway) ||
    ($.eventName = DeleteCustomerGateway) ||
    ($.eventName = AttachInternetGateway) ||
    ($.eventName = CreateInternetGateway) ||
    ($.eventName = DeleteInternetGateway) ||
    ($.eventName = DetachInternetGateway)}
  EOT

  metric_transformation {
    name      = "network_gateway_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "route_tables_changes_metric" {
  name           = "route_tables_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventName = CreateRoute) ||
    ($.eventName = CreateRouteTable) ||
    ($.eventName = ReplaceRoute) ||
    ($.eventName = ReplaceRouteTableAssociation) ||
    ($.eventName = DeleteRouteTable) ||
    ($.eventName = DeleteRoute) ||
    ($.eventName = DisassociateRouteTable)}
  EOT

  metric_transformation {
    name      = "route_tables_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "vpc_changes_metric" {
  name           = "vpc_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
    {($.eventName = CreateVpc) ||
    ($.eventName = DeleteVpc) ||
    ($.eventName = ModifyVpcAttribute) ||
    ($.eventName = AcceptVpcPeeringConnection) ||
    ($.eventName = CreateVpcPeeringConnection) ||
    ($.eventName = DeleteVpcPeeringConnection) ||
    ($.eventName = RejectVpcPeeringConnection) ||
    ($.eventName = AttachClassicLinkVpc) ||
    ($.eventName = DetachClassicLinkVpc) ||
    ($.eventName = DisableVpcClassicLink) ||
    ($.eventName = EnableVpcClassicLink) }
  EOT

  metric_transformation {
    name      = "vpc_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "organization_changes_metric" {
  name           = "organization_changes_metric"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = <<EOT
  {($.eventSource = organizations.amazonaws.com) &&
    (($.eventName = AcceptHandshake) ||
    ($.eventName = AttachPolicy) ||
    ($.eventName = CreateAccount) ||
    ($.eventName = CreateOrganizationalUnit) ||
    ($.eventName = CreatePolicy) ||
    ($.eventName = DeclineHandshake) ||
    ($.eventName = DeleteOrganization) ||
    ($.eventName = DeleteOrganizationalUnit) ||
    ($.eventName = DeletePolicy) ||
    ($.eventName = DetachPolicy) ||
    ($.eventName = DisablePolicyType) ||
    ($.eventName = EnablePolicyType) ||
    ($.eventName = InviteAccountToOrganization) ||
    ($.eventName = LeaveOrganization) ||
    ($.eventName = MoveAccount) ||
    ($.eventName = RemoveAccountFromOrganization) ||
    ($.eventName = UpdatePolicy) ||
    ($.eventName = UpdateOrganizationalUnit))}
  EOT

  metric_transformation {
    name      = "organization_changes_metric"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "ecs_task_start_failure" {
  name = "ecs_task_start_failure"

  pattern        = <<EOT
{
  ($.detail.stopCode = "TaskFailedToStart" && $.detail-type = "ECS Task State Change")
}
EOT
  log_group_name = var.cloudwatch_ecs_events_name

  metric_transformation {
    name      = "ecs_task_start_failure"
    namespace = "ECS"
    value     = "1"
    unit      = "Count"
    dimensions = {
      group = "$.detail.group"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "ecs_exec_cmd_task_failure" {
  name = "ecs_exec_cmd_task_failure"

  pattern        = <<EOT
{
  ($.detail-type = "ECS Task State Change" && $.detail.stopCode != "SpotInterruption" && $.detail.stopCode != "ServiceSchedulerInitiated" && $.detail.containers[0].exitCode != 0)
}
EOT
  log_group_name = var.cloudwatch_ecs_events_name

  metric_transformation {
    name      = "ecs_exec_cmd_task_failure"
    namespace = "ECS"
    value     = "1"
    unit      = "Count"
    dimensions = {
      group = "$.detail.group"
    }
  }
}

moved {
  from = aws_cloudwatch_log_metric_filter.ecs_task_failure
  to   = aws_cloudwatch_log_metric_filter.ecs_task_start_failure
}
