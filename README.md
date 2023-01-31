# EPB AWS Infrastructure

## Terraform Setup

### Installation
To install Terraform follow the instructions here (for Mac and Windows): 
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### Adding a profile to your AWS config and credentials
To change the AWS infrastructure for each environment, you need to setup an AWS 
profile on your machine.

#### Step 1

Add a profile to your AWS config file to access the environment:  
`[profile {profile_name_for_AWS_environment}]`  
`mfa_serial=arn:aws:iam::{AWS_organisation_account_id}:mfa/{IAMUser}`  
`role_arn=arn:aws:iam::{AWS_environment_account_id}}:role/developer`

Example:   
`[profile integration]`  
`mfa_serial=arn:aws:iam::123456789987654321:mfa/firstname.surname`  
`role_arn=arn:aws:iam::123456789:role/developer`

    
#### Step 2

Add the access key id and secret key for the profile in the AWS credentials file. Use the credentials for your existing IAM user, check in the AWS console to verify they match.

`[{profile_name_for_AWS_environment}]`  
`aws_access_key_id = {IAMUser_aws_access_key_id}`  
`aws_secret_access_key = {IAMUser_aws_secret_access_key}`

Example:  
`[integration]`  
`aws_access_key_id = ABC123DEF456GHI789`  
`aws_secret_access_key = B1l1o1o1p123456879`

#### Step 3

If using aws-vault, you will also need add a user:  
`aws-vault add {profile_name_for_AWS_environment}`

Example:  
`aws-vault add integration`

### Using the S3 backend
Before starting to terraform the infrastructure of an environment, you will need to use the pre-configured S3
backend, so that terraform can store / lock the state

The infrastructure used for the S3 backend is defined via terraform in the `/state-init` directory

#### Step 1

Run:
` cd /state-init`   

To initialise the backend S3 bucket and dynamo db config, run:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform init`

Example:  
`aws-vault exec integration -- terraform init`

#### Step 2

Go to the root of the project. To initialise the backend and environment infrastructure config, run:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform init -backend-config=backend_{profile}.hcl`

Example:  
`aws-vault exec integration -- terraform init -backend-config=backend_integration.hcl`

#### Step 3

Run a terraform plan and check you see everything is upto date:  
`aws-vault exec {profile_name_for_AWS_environment} -- terraform plan`

Example:  
`aws-vault exec integration -- terraform plan`


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
