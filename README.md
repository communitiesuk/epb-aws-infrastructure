# EPB AWS Infrastructure

## Terraform Setup

### Installation
To install Terraform follow the instructions here (for Mac and Windows): 
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### Adding a profile to your AWS config and credentials
In order to be able to make changes to the AWS infrastructure, you will need to setup your AWS profile first on your machine

Begin by adding a profile to your AWS config file that will be used to access the environment e.g.  
`[profile {AWSEnvironment}]`  
`mfa_serial=arn:aws:iam::{AWS_organisation_account_id}:mfa/{IAMUser}`  
`role_arn=arn:aws:iam::{AWS_environment_account_id}}:role/developer`

Then add the access key and secret key credentials for that profile (using the credentials for your existing IAM user)
in the AWS credentials file e.g.  
`[{profile}]`  
`aws_access_key_id = {IAMUser_aws_access_key_id}`  
`aws_secret_access_key = {IAMUser_aws_secret_access_key}`

If you are using aws-vault you will also need add a user e.g.  
`aws-vault add {profile}`

### Using the S3 backend
Before starting to terraform the infrastructure of an environment, you will need to be able to use the pre-configured S3
backend, so that terraform can store / lock the state

The infrastructure used for the S3 backend is defined via terraform in the `/state_int` directory

First cd into it and run the cmd below, to initialise the backend S3 bucket and dynamo db config:  
`aws-vault exec {profile} -- terraform init`

Then go to the root of the project, and run the below to initialise the backend and environment infrastructure config:  
`aws-vault exec {profile} -- terraform init -backend-config=backend_{profile}.hcl`

Finally, run a terraform plan and check that you see that everything is upto date using the command below:  
`aws-vault exec {profile} -- terraform plan`

## Commit messages
When making a commit to the repo, please follow a semantic commit message format, see the link below for more info:
https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716

If the commit is not attached to a ticket then the format will generally be:  
`type: Subject`

And if it is for a particular ticket, prefix the ticket number e.g.  
`EPBR-XXXX: type: Subject`
