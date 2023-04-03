data "aws_ssm_parameter" "alert_slack_webhook_url" {
  name = "EPB_TEAM_SLACK_URL"
}
