# EPBR Code Pipelines

## Local AWS profile management

To change the AWS code-pipelines, you need to setup an AWS profile on your machine. There are 2 options:
* manually
* `aws-vault`

### Manual option

1. Add a profile to your AWS config file to access the environment:  
   `[profile {profile_name_for_AWS_CICD_environment}]`  
   `mfa_serial=arn:aws:iam::{aws_organisation_account_id}:mfa/{IAMUser}`  
   `role_arn=arn:aws:iam::{aws_cicd_account_id}:role/developer`

    Example  
    `[profile cicd]`  
    `mfa_serial=arn:aws:iam::111111111:mfa/firstname.surname`  
    `role_arn=arn:aws:iam::123456789:role/developer`

2. Add the access key id and secret key for the profile in the AWS credentials file. Use the credentials for your 
existing IAM user, check in the AWS console to verify they match.

   `[{profile_name_for_AWS_CICD_environment}]`  
   `aws_access_key_id = {IAMUser_aws_access_key_id}`  
   `aws_secret_access_key = {IAMUser_aws_secret_access_key}`
    
    Example:  
    `[cicd]`  
    `aws_access_key_id = ABC123DEF456GHI789`  
    `aws_secret_access_key = B1l1o1o1p123456879`

3. If using `aws-vault` to execute commands later, you will also need add a user:  
   `aws-vault add {profile_name_for_AWS_environment}`

   Example:  
   `aws-vault add cicd`

### AWS Vault option

Follow instructions in [official AWS Vault documentation](https://github.com/99designs/aws-vault/blob/master/USAGE.md#config)

## Adding local secret vars

The code pipelines reside in the AWS CICD account, but need access to the AWS accounts of the service environments

The account IDs of any service environments need to be referenced from a local file you'll need to add. This file is in 
the .gitignore and not a public parameter. To set this up:

1. Changed your current working directory to `/code-pipeline/service-pipeline`
2. Create a file `.auto.tfvars` in that directory
3. In the file add the following, replacing `{aws_integration_account_id}` with the integration account ID  
   `account_ids = { {environment_name}="{aws_environment_account_id}" }`   
   `cross_account_role_arns = ["arn:aws:iam::{aws_environment_account_id}:role/ci-server"]` 

    Example:  
   `account_ids = { integration="111111111" }`   
   `cross_account_role_arns = ["arn:aws:iam::111111111:role/ci-server"]`
4. Save the file.

## Setup making changes

1. Make sure you have changed your current working directory to `/code-pipeline/service-pipelines`

2. Initialize your Terraform environment  
    `aws-vault exec {aws_profile_name_for_CICD_environment} -- terraform init -backend-config=backend_cicd.hcl`  
    Example:  
    `aws-vault exec cicd -- terraform init -backend-config=backend_cicd.hcl`

## Creating the infrastructure for the EPBR code pipelines

To create the infrastructure for the pipelines, run the terraform commands below:

`aws-vault exec {aws_profile_name_for_CICD_environment} -- terraform plan`   
Example:   
`aws-vault exec cicd -- terraform plan`

`aws-vault exec {aws_profile_name_for_CICD_environment} -- terraform apply`  
Example:   
`aws-vault exec cicd -- terraform apply`

## Overview of the Terraform methodology for defining the pipeline infrastructure

Each pipeline is a module which can be accessed from the `/modules/` directory

Many of the resources required for each pipeline (eg. s3 bucket, codestar connector and code pipeline roles are) 
terraformed as global resources in the `code-pipeline/service-pipelines/modules.tf` file

These resources are then passed into each individual pipeline, see `/service-pipelines/modules.tf`

One exception is the code build role. Permission for this depend on whether the pipeline requires access to resources in 
a different account e.g. the auth server, or the same account e.g. the code build image pipeline. For the latter it uses 
a code build role that has fewer permissions than the former

## Adding a new pipeline

- Create a new module with the new name of pipeline you wish to add 
- Add a code_pipleline.tf file and add your pipeline using the pre-existing global resources 
- Include the module in the `code-pipeline/service-pipelines/modules.tf` file passing in any resources required.
- Adding a new module will require you to re-initialise the Terraform in the same way as in step 3