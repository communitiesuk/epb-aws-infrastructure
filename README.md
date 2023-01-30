# EPB AWS Infrastructure

## Set up backend
 Before starting to terraform an environment you will need to set up the terraform back end for that environment.
 The terraform commands for this are stored in the /state_int directory
 To run the terraform to create the back end you will need to add credentials to your AWS config and credentials
 Add a profile to your AWS config file you will use to access the environment. eg.

`[profile {AWSEnvironment}]
mfa_serial=arn:aws:iam::{AWS_organisation_account_id}:mfa/{IAMUser}
role_arn=arn:aws:iam::{AWS_environment_account_id}}:role/developer`

Then add the AWS credentials for that profile in the credentials file using the credentials for your existing IAM user

`[{profile}]
aws_access_key_id = {IAMUser_aws_access_key_id}
aws_secret_access_key = {IAMUser_aws_secret_access_key}`

If you are using aws-vault you will need add a user like so
`aws-vault add {profile}`

You can then terraform the back end using the following cmd. First cd into the state_init directory then run:

`aws-vault exec {profile} -- terraform init -backend-config=backend_{profile}.hcl`