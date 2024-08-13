resource "aws_codestarconnections_connection" "codestar_connection" {
  name          = "communitiesuk-connection"
  provider_type = "GitHub"
}
