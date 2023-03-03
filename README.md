# EPB AWS Infrastructure

## Terraform Setup

### Installation

1. Install Terraform:
<https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
2. Install AWS Vault: <https://github.com/99designs/aws-vault>

## Local AWS profile management

To change the AWS infrastructure for each environment, you need to setup an AWS
profile on your machine. There are 2 options:

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

2. Add the access key id and secret key for the profile in the AWS credentials file. Use the credentials for your
existing IAM user, check in the AWS console to verify they match.

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

Follow instructions in [official AWS Vault documentation](https://github.com/99designs/aws-vault/blob/master/USAGE.md#config)

## Setting up tfstate management (Initial setup only)

*Skip this if the infrastructure state management exists already*

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

## Deploying image to ECR

1. Retrieve an authentication token and authenticate your Docker client to your registry.
    Use the AWS CLI:

    `docker login -u AWS -p $(aws-vault exec {profile_name_for_AWS_environment} -- aws ecr get-login-password --region eu-west-2) {account_id}.dkr.ecr.eu-west-2.amazonaws.com`

    Note: if you receive an error using the AWS CLI, make sure that you have the latest version of the AWS CLI and Docker installed.

1. Build your Docker image using the following command. For information on building a Docker file from scratch, see the
instructions here . You can skip this step if your image has already been built:

    `docker build -t {local_image_name} .`

1. After the build is completed, tag your image so you can push the image to this repository:

    `docker tag {local_image_name}:latest {account_id}.dkr.ecr.eu-west-2.amazonaws.com/{ecr_name}:latest`

1. Run the following command to push this image to your newly created AWS repository:

    `docker push {account_id}.dkr.ecr.eu-west-2.amazonaws.com/{ecr_name}:latest`

### e.g for auth server in integration run the following commands

   `docker login -u AWS -p $(aws-vault exec integration -- aws ecr get-login-password --region eu-west-2) 851965904888.dkr.ecr.eu-west-2.amazonaws.com`

   `docker build -t epb-auth-service .`

   `docker tag epb-auth-service:latest 851965904888.dkr.ecr.eu-west-2.amazonaws.com/epb-intg-auth-service-ecr:latest`

   `docker push 851965904888.dkr.ecr.eu-west-2.amazonaws.com/epb-intg-auth-service-ecr:latest`

For information on Terraforming the EPBR Code pipelines go to `/code-pipeline/README.md`

## Restarting a service

After making changes to secrets or parameters, you will need to restart a service for changes to take place

`SERVICE={service_name}; aws-vault exec integration -- aws ecs update-service --cluster epb-intg-$SERVICE-cluster --service epb-intg-$SERVICE --force-new-deployment`

where `service_name` should be replaced with the name of the service, e.g. `auth-service`

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

## Static analysis with tfsec

You will need tfsec installed

On Mac `brew install tfsec`

On Windows `choco install tfsec`

### Running tfsec

You can simply run `tfsec` in root folder

You can see the options with `tfsec -h`

one useful option is setting `--minimum-severity` flag

`tfsec --minimum-severity HIGH` will ignore any *Low* adn *Medium* issues
