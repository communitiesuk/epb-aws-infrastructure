# Code Pipeline For EPBR Auth Server

Code pipeline for deploying Auth Server Service

1. Set up environment for CICD

Before you run you will need the ID of the aws epbr cicd account
Open the AWS config file ~/.aws/config and the configuration

`[profile cicd]
mfa_serial=arn:aws:iam::{aws_organisation_account_id}:mfa/{aws_iam_user}
role_arn=arn:aws:iam::{aws_cicd_account_id}:role/developer`

- update the  ~/.aws/credentials

`[cicd]
aws_access_key_id = {aws_iam_user_access_key}
aws_secret_access_key = {aws_iam_user_secret_access_key}`

- if using aws-vault, add the cicd profile to your aws-vault
  `aws-vault add cicd`

2 Add local secret vars
The code pipeline runs on the CICD account and needs access to the accounts for the service environments
The accounts ID for the service environments are referenced from a local file that is in the .gitignore and therefore not a public parameter.
To add this file make sure you have changed your current working directory to /code-pipeline/auth-server
create a file `.auto.tfvars` in that directory. 
In the file add the following
`account_ids = { integration="{aws_integration_account_id}" } ` replacing {aws_integration_account_id} with the integration account ID
save the file.

3 Initialize your Terraform environment  
make sure you have changed your current working directory to /code-pipeline/auth-server
`aws-vault exec cicd -- terraform init`

4  Create infrastructure
`aws-vault exec cicd -- terraform apply`
