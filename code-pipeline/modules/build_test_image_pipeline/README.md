# Codepipeline for EBPR Codebuild images

Pipeline for building dockers images from a named repo used in the build and test phase of service pipelines

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

- if using aws-vault added the cicd profile to aws-vault
`aws-vault add cicd`


2 Initialize your Terraform environment  
make sure you have changed your current working directory to /code-pipeline/codebuild_image
`aws-vault exec cicd -- terraform init`

3  Create infrastructure
`aws-vault exec cicd -- terraform apply`
