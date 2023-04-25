# EPBR CI (Continuous Integration)

This is repo for terraforming resources in the EPBR CI account, including code pipelines.

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

### tfvars

In terraform, we use modules which may require variables to be set. Even the top level (root) terraform definitions may require variables.

These variables may be sensitive, so they should be stored securely and not checked into git.

To avoid having to type each var whenever you run `terraform apply` command, it is good idea to keep a private set of variables in `tfvars` file.
Better yet, to make things less verbose to run, store them in `.auto.tfvars` file.

Example `.auto.tfvars` file:

```hcl
account_ids = {
  integration="123456789012"
  staging="1111111111111"
}
cross_account_role_arns = [
  "arn:aws:iam::123456789012:role/ci-server-role",
  "arn:aws:iam::1111111111111:role/ci-server-role",
]
```

More info in [official documentation](https://developer.hashicorp.com/terraform/language/values/variables)

### Maintaining tfvars

tfvars are currently stored alongside the state file in the S3 bucket `epbr-terraform-state`.
When updating the tfvars, make sure you update the file in the S3 bucket to avoid others being unable to deploy their changes.

There are handy `just` scripts which automate the process:

```bash
just tfvars-put-for-ci {path} # where path is the where your ci folder is relative to the present directory you're in e.g. "./ci"

just tfvars-get-for-ci {path} # where path is the where your ci folder is relative to the present directory you're in e.g. "./ci"
```

#### Securely handling tfvars

Currently the tfvars are stored in plaintext on your machine to run the terraform scripts.
We are planning on moving sensitive values to a more secure place.
Until then, take care when handling the tfvars

* Don't check them into git!
* When adding new vars, mark them as `sensitive = true` in Terraform
* If you are worried about security of files, don't store them on your machine - only download them to run the script, then delete or encrypt. Always do this for production
* Only pass them to others via the S3 bucket, as documented in previous section

## Adding local secret vars

The code pipelines reside in the AWS CICD account, but need access to the AWS accounts of the service environments

The account IDs of any service environments need to be referenced from a local file you'll need to add. This file is in
the .gitignore and not a public parameter. To set this up:

1. Change your current working directory to `/ci`
2. Create a file `.auto.tfvars` in that directory
3. In the file add the following, replacing `{aws_integration_account_id}` with the integration account ID  
   `account_ids = { {environment_name}="{aws_environment_account_id}" }`
   `cross_account_role_arns = ["arn:aws:iam::{aws_environment_account_id}:role/ci-server"]`

    Example:  
   `account_ids = { integration="111111111" }`
   `cross_account_role_arns = ["arn:aws:iam::111111111:role/ci-server"]`
4. Save the file.

## Setup making changes

1. Make sure you have changed your current working directory to `ci`

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
terraformed as global resources in the `ci/modules.tf` file

These resources are then passed into each individual pipeline, see `ci/modules.tf`

One exception is the code build role. Permission for this depend on whether the pipeline requires access to resources in
a different account e.g. the auth server, or the same account e.g. the code build image pipeline. For the latter it uses
a code build role that has fewer permissions than the former

## Adding a new pipeline

* Create a new module with the new name of pipeline you wish to add
* Add a code_pipleline.tf file and add your pipeline using the pre-existing global resources
* Include the module in the `ci/modules.tf` file passing in any resources required.
* Adding a new module will require you to re-initialise the Terraform in the same way as in step 3

## Linting with tflint

You will need tflint installed

On Mac `brew install tflint`

On Windows `choco install tflint`

Note: Windows version doesn't allow for recursive call, which is sad.
You may be better off running docker version

### Running tflint

You need to be in the project root

On Mac `tflint --recursive`

On Windows you don't have `--recursive`, so `tflint {path_to_module}`

On Windows with Docker `docker run --rm -v ${pwd}:/data -t ghcr.io/terraform-linters/tflint --recursive`

*TIP: use `--format=compact` to make output easier to read.*
