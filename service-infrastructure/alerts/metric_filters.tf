resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls_metric" {
  name           = "UnautorizedApiCalls"
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = <<EOT
    {($.errorCode = UnauthorizedOperation) ||
    ($.errorCode = AccessDenied) ||
    ($.sourceIPAddress != "delivery.logs.amazonaws.com") ||
    ($.eventName != HeadBucket) }
  EOT

  metric_transformation {
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "root_account_login_metric" {
  name           = "RootAccountLogin"
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = <<EOT
    {($.userIdentity.type = Root) &&
    ($.userIdentity.invokedBy NOT EXISTS) &&
    ($.eventType != AwsServiceEvent)}
    EOT

  metric_transformation {
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes_metric" {
  name           = "IamPolicyChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
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
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_config_changes_metric" {
  name           = "CloudtrailConfigChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = <<EOT
    {($.eventName = CreateTrail) ||
    ($.eventName = UpdateTrail) ||
    ($.eventName = DeleteTrail) ||
    ($.eventName = StartLogging) ||
    ($.eventName = StopLogging)}
    EOT

  metric_transformation {
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes_metric" {
  name           = "S3BucketPolicyChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
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
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes_metric" {
  name           = "NetworkGatewayChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = <<EOT
    {($.eventName = CreateCustomerGateway) ||
    ($.eventName = DeleteCustomerGateway) ||
    ($.eventName = AttachInternetGateway) ||
    ($.eventName = CreateInternetGateway) ||
    ($.eventName = DeleteInternetGateway) ||
    ($.eventName = DetachInternetGateway)}
  EOT

  metric_transformation {
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "route_tables_changes_metric" {
  name           = "RouteTablesChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
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
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "vpc_changes_metric" {
  name           = "VpcChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
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
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "organization_changes_metric" {
  name           = "OrganizationChanges"
  log_group_name = aws_cloudwatch_log_group.this.name
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
    name      = "EventCount"
    namespace = "CISBenchmark"
    value     = "1"
  }
}