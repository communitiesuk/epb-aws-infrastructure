# EPB AWS Infrastructure

## Setting up an S3 backend for Terraform
Before starting to terraform the infrastructure of an environment, you will need to set up an S3 backend so that terraform
can store its state

The infrastructure used for the S3 backend is defined via terraform in the `/state_int` directory

Before setting up the S3 backend, you will need to add a profile to your AWS config and credentials as below

### Adding a profile to your AWS config and credentials
Add a profile to your AWS config file that will be used to access the environment e.g.  
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

### Initialising the S3 backend
Once you've updated your AWS profiles, you can initialise the terraform backend using the following cmd. 

First cd into the `/state_init` directory then run:

`aws-vault exec {profile} -- terraform init -backend-config=backend_{profile}.hcl`