# EPB AWS Infrastructure

## Terraform Setup

### Installation
To install Terraform follow the instructions here (for Mac and Windows): 
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### Adding a profile to your AWS config and credentials
In order to be able to make changes to the AWS infrastructure for a given environment, you will need to setup an AWS 
profile for it first on your machine

Begin by adding a profile to your AWS config file that will be used to access the environment. e.g.  
`[profile {profile_name_for_AWS_environment}]`  
`mfa_serial=arn:aws:iam::{AWS_organisation_account_id}:mfa/{IAMUser}`  
`role_arn=arn:aws:iam::{AWS_environment_account_id}}:role/developer`

Then add the access key id and secret key for that profile (using the credentials for your existing IAM user)
in the AWS credentials file e.g.  
`[{profile_name_for_AWS_environment}]`  
`aws_access_key_id = {IAMUser_aws_access_key_id}`  
`aws_secret_access_key = {IAMUser_aws_secret_access_key}`

If you are using aws-vault you will also need add a user e.g.  
`aws-vault add {profile_name_for_AWS_environment}`

### Using the S3 backend
Before starting to terraform the infrastructure of an environment, you will need to be able to use the pre-configured S3
backend, so that terraform can store / lock the state

The infrastructure used for the S3 backend is defined via terraform in the `/state-init` directory

First cd into `/state-init` and run the cmd below, to initialise the backend S3 bucket and dynamo db config:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform init`

Then go to the root of the project, and run the below to initialise the backend and environment infrastructure config:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform init -backend-config=backend_{profile}.hcl`

Finally, run a terraform plan and check you see that everything is upto date using the command below:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform plan`

## Commit messages
When making a commit to the repo, please follow a semantic commit message format, see the link below for more info:  
https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716

If the commit is not attached to a ticket then the format will generally be:  
`type: Subject`

And if it is for a particular ticket, prefix the ticket number e.g.  
`EPBR-XXXX: type: Subject`

## Making changes to the AWS Infrastructure using Terraform
When making changes in terraform, you should run the plan command below to check the changes terraform believes it needs
to make and confirm it all looks sensible  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform plan`

Once you are happy with these, you will then need to apply them in order for the changes to take effect in AWS  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform apply`

Once successfully applied, it is recommended that you go into the AWS Management Console and sanity check the changes 
have been applied as you expected
