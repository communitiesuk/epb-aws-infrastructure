# EPB AWS Infrastructure

## just

A lot of tasks described in this readme have been made easier using `just`. It is similar to `make`, but with some neater syntax and cross platform support.

[Official Documentation](https://github.com/casey/just)

### Installing just

Mac: `brew install just`

Windows: `choco install just`

On Windows, open your bash of choice (e.g. Git bash).
Make sure you are in the root, where `justfile` is located.

Run:
`just install`
`source ~/.bash_profile`

This sets up alias `.j` to use this specific file.

Example usage: `.j tfsec`

### Usage

To view available recipes, run `just` in this project or `.j` anywhere

When specifying paths in `just` command, provide absolute paths. You can use `$(pwd)` to get current path e.g.

```bash
cd code-pipeline/service-pipelines/
.j tf-init $(pwd) $(pwd)/backend_cicd.hcl
```

## Terraform Setup

### Terraform installation

1. Install Terraform:
<https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
1. Install AWS Vault: <https://github.com/99designs/aws-vault>
1. Setup your aws access [via aws-vault profile](https://tech-docs.epcregisters.net/dev-setup.html#create-an-aws-vault-profile)

### tfvars

In terraform, we use modules which may require variables to be set. Even the top level (root) terraform definitions may require variables.

These variables may be sensitive, so they should be stored securely and not checked into git.

To avoid having to type each var whenever you run `terraform apply` command, it is good idea to keep a private set of variables in `tfvars` file.
Better yet, to make things less verbose to run, store them in `.auto.tfvars` file.

Example `.auto.tfvars` file:

```hcl
account_map = {
  "integration" = "123456789012",
  "staging" = "1111111111111",
}

prefix = "some-string-prefix"

some_list = [1, 5, 2]
```

More info in [official documentation](https://developer.hashicorp.com/terraform/language/values/variables)

#### Maintaining tfvars

tfvars are currently stored alongside the state file in the S3 bucket `epbr-{env}-terraform-state`.
When updating the tfvars, make sure you update the file in the S3 bucket to avoid others being unable to deploy their changes.

There are handy `just` scripts which automate the process:

```bash
just tfvars-put service-infrastructure {env}  # where env is one of integration, staging or production

just tfvars-get service-infrastructure {env}  # where env is one of integration, staging or production
```

#### Securely handling tfvars

Currently the tfvars are stored in plaintext on your machine to run the terraform scripts.
We are planning on moving sensitive values to a more secure place.
Until then, take care when handling the tfvars

* Don't check them into git!
* When adding new vars, mark them as `sensitive = true` in Terraform
* If you are worried about security of files, don't store them on your machine - only download them to run the script, then delete or encrypt. Always do this for production
* Only pass them to others via the S3 bucket, as documented in previous section

## Setting up tfstate management (Initial setup only)

__Note__: Skip this if the infrastructure state management exists already

Before starting to terraform the infrastructure of an environment, you will need to use the pre-configured S3
backend, so that terraform can store / lock the state.

The infrastructure used for the S3 backend is defined via terraform in the `/state-init` directory:

1. `cd /state-init`

1. Initialize your Terraform enivronment  
    `aws-vault exec {profile_name_for_AWS_environment} -- terraform init`

    Example:  
    `aws-vault exec integration -- terraform init`

1. Create infrastructure
    `aws-vault exec {profile_name_for_AWS_environment} -- terraform apply`

    Example:  
    `aws-vault exec integration -- terraform apply`


## Terraforming infrastrcuture
The repo is sub divided into terraform for the following EPB infrastructure
 - /service-infrastructure  terraform for all resources in  AWS EPB integration, staging and production accounts
 - /ci terraform for all resources in AWS EPB cicd account
 - /developer terraform for all resources in  AWS EPB  developer account


## Setup making changes to service-infrastructure

1. From root `cd service-infrastructure`

2. Initialize your Terraform environment

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform init -backend-config=backend_{profile}.hcl`

    Example:

    `aws-vault exec integration -- terraform init -backend-config=backend_integration.hcl`

3. To run terraform you will need to download a copy of the parameters stored as tfvars in the environment. To do this run

    `just tfvars-get service-infrastructure {profile_name_for_AWS_environment}`

4. Run a terraform plan and check you see everything is upto date:

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform plan`

    Example:  
    `aws-vault exec integration -- terraform plan`

## Making changes

1. First, generate a plan to check the changes Terraform wants to make

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform plan -out=tfplan`

2. Once happy that the changes are as expected, apply them

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform apply tfplan`

3. (Optional) Once successfully applied, you should be able to see the changes in the AWS Management Console.
Sanity check the changes have been applied as you expected

## Making changes using just

1. make sure you have switch profile to the correct env

    `just set-profile  {profile_name_for_AWS_environment}`

1. download a copy of the parameters stored as tfvars in the environment. To do this run

    `just tfvars-get service-infrastructure {profile_name_for_AWS_environment}`

1. run the apply

    ` just tf-apply service-infrastructure `

## Deleting infrastructure

When deployed infrastructure is no longer needed

1. `aws-vault exec {profile_name_for_AWS_environment} -- terraform destroy`

1. Because the state of the S3 and DynamoDB are not stored in a permanent backend, those resources should be deleted
through AWS console

## Restarting a service

After making changes to secrets or parameters, you will need to restart a service for changes to take place

`SERVICE={service_name}; aws-vault exec integration -- aws ecs update-service --cluster $SERVICE-cluster --service $SERVICE --force-new-deployment`

where `service_name` should be replaced with the name of the service, e.g. `epb-intg-auth-service`

## Linting with tflint

You will need tflint installed

On Mac `brew install tflint`

On Windows it is recommended to use docker and the Windows locally installed version doesn't allow for a recursive call

### Running tflint

You need to be in the project root

On Mac `tflint --recursive`

On Windows, use a Powershell terminal (as the command doesn't work in a Bash terminal) and do  
`docker run --rm -v ${pwd}:/data -t ghcr.io/terraform-linters/tflint --recursive`

*TIP: use `--format=compact` to make output easier to read.*

## Static analysis with tfsec

You will need tfsec installed

On Mac `brew install tfsec`

On Windows `choco install tfsec`

### Running tfsec

You can simply run `tfsec` in root folder

You can see the options with `tfsec -h`

one useful option is setting `--minimum-severity` flag

`tfsec --minimum-severity HIGH` will ignore any *Low* adn *Medium* issues

## Other infrastructure related tasks

You can see full documentation about 
[working in our AWS accounts](https://tech-docs.epcregisters.net/aws-migration.html#setting-up-ssl-certificates) in tech
docs.


## Setup making changes to ci
1. From root `cd ci`
2. Follow the steps from making changes to service-infrastructure only change the profile to ci (or whatever AWS profile name you have the ci account set for)
3. Download the latest version of the .auto.tfVars from AWS using the just cmd  `tfvars-get-for-ci`
4. If you make changes to .auto.tfVars remember to upload it back to AWS `tfvars-put-for-ci`

## Setup making changes to developer
1. From root `cd developer`
2. Follow the steps from making changes to service-infrastructure only change the profile to developer (or whatever AWS profile name you have the developer account set for)
3. Download the latest version of the .auto.tfVars using the just cmd  `tfvars-get-dev`
4. If you make changes to .auto.tfVars remember to upload it back to AWS `tfvars-put-dev`


NB not all resources in the developer account are tracked by the current state. The state contains resources created as part of or after the switch off PaaS
