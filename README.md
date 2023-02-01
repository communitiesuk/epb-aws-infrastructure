# EPB AWS Infrastructure

## Terraform Setup

### Installation
1. Install Terraform: 
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
2. Install AWS Vault: https://github.com/99designs/aws-vault


## Local AWS profile management
To change the AWS infrastructure for each environment, you need to setup an AWS 
profile on your machine. 
There are 2 options:
* manually
* `aws-vault`


### Manual option

1. Add a profile to your AWS config file to access the environment:  
    `[profile {profile_name_for_AWS_environment}]`  
    `mfa_serial=arn:aws:iam::{AWS_organisation_account_id}:mfa/{IAMUser}`  
    `role_arn=arn:aws:iam::{AWS_environment_account_id}}:role/developer`

    Example:   
    `[profile integration]`  
    `mfa_serial=arn:aws:iam::111111111:mfa/firstname.surname`  
    `role_arn=arn:aws:iam::123456789:role/developer`

2. Add the access key id and secret key for the profile in the AWS credentials file. Use the credentials for your existing IAM user, check in the AWS console to verify they match.

    `[{profile_name_for_AWS_environment}]`  
    `aws_access_key_id = {IAMUser_aws_access_key_id}`  
    `aws_secret_access_key = {IAMUser_aws_secret_access_key}`

    Example:  
    `[integration]`  
    `aws_access_key_id = ABC123DEF456GHI789`  
    `aws_secret_access_key = B1l1o1o1p123456879`

3. If using `aws-vault` to execute commands later, you will also need add a user:  
    `aws-vault add {profile_name_for_AWS_environment}`

    Example:  
    `aws-vault add integration`


### AWS Vault option

Follow instructions in [official AWS Valut documentation](https://github.com/99designs/aws-vault/blob/master/USAGE.md#config)


### Setting up tfstate management

Before starting to terraform the infrastructure of an environment, you will need to use the pre-configured S3
backend, so that terraform can store / lock the state

The infrastructure used for the S3 backend is defined via terraform in the `/state-init` directory

1. Run:
    
    `cd /state-init`   

    To initialise the backend S3 bucket and dynamo db config, run:  
    `aws-vault exec {profile_name_for_AWS_environment} -- terraform init`

    Example:  
    `aws-vault exec integration -- terraform init`

2. Go to the root of the project `cd ..`

    To initialise the backend and environment infrastructure config, run:  
    `aws-vault exec {profile_name_for_AWS_environment} -- terraform init -backend-config=backend_{profile}.hcl`

    Example:  
    `aws-vault exec integration -- terraform init -backend-config=backend_integration.hcl`


## Checking if the infrastructure is in synch with current Terraform code

Run a terraform plan and check you see everything is upto date:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform plan`

Example:  
`aws-vault exec integration -- terraform plan`


## Making changes

1. First, generate a plan to check the changes Terraform wants to make

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform plan -out=tfplan`

1. Once happy that the changes are as expected, apply them

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform apply tfplan`

1. (Optional) Once successfully applied, it is recommended that you go into the AWS Management Console and sanity check the changes have been applied as you expected


## Deleting infrastructure

When deployed infrastructure is no longer needed

1. `aws-vault exec {profile_name_for_AWS_environment} -- terraform destroy`

1. Because the state of the S3 and DynamoDB are not stored in a permanent backend, those resources should be deleted through AWS console
