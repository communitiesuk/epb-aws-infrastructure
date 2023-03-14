# EPB AWS Infrastructure

## just

A lot of tasks described in this readme have been made easier using `just`. It is similar to `make`, but with some neater syntax and cross platform support.

[Official Documentation](https://github.com/casey/just)

### Installation

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
.j tfinit $(pwd) $(pwd)/backend_cicd.hcl
```

## Terraform Setup

### Installation

1. Install Terraform:
<https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
1. Install AWS Vault: <https://github.com/99designs/aws-vault>
1. Setup your aws access [via aws-vault profile](https://dluhc-epb-tech-docs.london.cloudapps.digital/dev-setup.html#create-an-aws-vault-profile)

### tfvars

In terraform, we use modules which may require variables to be set. Even the top level (root) terraform definitions may require variables.

These variables may be sensitive, so they should be stored securely and not checked into git. TODO: Add method for secure storage for easier sharing.

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

## Setup making changes

1. From root `cd service-infrastructure`

1. Initialize your Terraform environment  
    `aws-vault exec {profile_name_for_AWS_environment} -- terraform init -backend-config=backend_{profile}.hcl`

    Example:  
    `aws-vault exec integration -- terraform init -backend-config=backend_integration.hcl`

1. Run a terraform plan and check you see everything is upto date:  
    `aws-vault exec {profile_name_for_AWS_environment} -- terraform plan`

    Example:  
    `aws-vault exec integration -- terraform plan`

## Making changes

1. First, generate a plan to check the changes Terraform wants to make

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform plan -out=tfplan`

1. Once happy that the changes are as expected, apply them

    `aws-vault exec {profile_name_for_AWS_environment} -- terraform apply tfplan`

1. (Optional) Once successfully applied, you should be able to see the changes in the AWS Management Console.
Sanity check the changes have been applied as you expected

## Deleting infrastructure

When deployed infrastructure is no longer needed

1. `aws-vault exec {profile_name_for_AWS_environment} -- terraform destroy`

1. Because the state of the S3 and DynamoDB are not stored in a permanent backend, those resources should be deleted
through AWS console

## Restarting a service

After making changes to secrets or parameters, you will need to restart a service for changes to take place

`SERVICE={service_name}; aws-vault exec integration -- aws ecs update-service --cluster $SERVICE-cluster --service $SERVICE --force-new-deployment`

where `service_name` should be replaced with the name of the service, e.g. `epb-intg-auth-service`

## Setting up SSL Certificates

When a new SSL certificate is made because of running `terraform apply` (e.g. because we're setting up the infrastructure 
for a new environment), you may come across issues trying to associate it with a resource because you need to validate 
and completely setup the SSL certificate first. See the tech-docs
[here](https://dluhc-epb-tech-docs.london.cloudapps.digital/aws-migration.html#setting-up-ssl-certificates) for instructions
on how to do this

## Setting up DNS Alias Records for CloudFront

When new CloudFront distributions are made for each of the services (say because you run `terraform apply` to deploy 
infrastructure to an AWS environment for the first time), AWS will give domain names for each distribution, 
and we need to put/add these in DNS Alias Records in order to be able to complete the CloudFront setup. See the tech-docs 
[here](https://dluhc-epb-tech-docs.london.cloudapps.digital/aws-migration.html#adding-dns-alias-records-for-cloudfront) 
for instructions on how to do this 

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

You can see broader documentation of AWS Migration and related tasks in [tech docs](https://dluhc-epb-tech-docs.london.cloudapps.digital/aws-migration.html)