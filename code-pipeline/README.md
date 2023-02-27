# Code Pipelines For EPBR 

Terraform for all the CICD Code pipelines

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
  
- `aws-vault add cicd`

2. Add local secret vars

The code pipeline runs on the CICD account and needs access to the accounts for the service environments
The accounts ID for the service environments are referenced from a local file that is in the .gitignore and therefore not a public parameter.
To add this file make sure you have changed your current working directory to /code-pipeline/service-pipeline
create a file `.auto.tfvars` in that directory. 
In the file add the following

`account_ids = { integration="{aws_integration_account_id}" }
cross_account_role_arns = ["arn:aws:iam::{aws_integration_account_id}:role/ci-server"]` 

replacing {aws_integration_account_id} with the integration account ID
save the file.

3. Initialize your Terraform environment using the state-int module

Make sure you have changed your current working directory to /code-pipeline/service-pipelines

`aws-vault exec cicd -- terraform init -backend-config=backend_cicd.hcl`

4.  Create infrastructure for all the EPBR code pipelines

`aws-vault exec cicd -- terraform plan`
`aws-vault exec cicd -- terraform apply`

Each pipeline is a module which can be accessed from the `/modules/` directory
Many of the resources required for each pipeline (eg. s3 bucket, codestar connector and code pipeline roles are) terraformed as global resources in the `code-pipeline/service-pipelines/modules.tf` file. 
These resources are passed into each individual pipeline.
One exception is the code build role. Permission for this depend on whether the pipeline requires access to resources in a different account e.g. the auth server or the same account e.g. the code build image pipeline
For latter it used a code build role that has fewer permissions than the former

5. Add a new pipeline

- Create a new module with the new name of pipeline you wish to add 
- Add a code_pipleline.tf file and add your pipeline using the pre-existing global resources 
- Include the module in the `code-pipeline/service-pipelines/modules.tf` file passing in any resources required.
- Adding a new module will require you to re-initialise the Terraform in the same way as in step 3