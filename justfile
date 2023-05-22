set dotenv-load

# List available commands
default:
    @just --list

# Install dependencies
[windows]
install:
    @choco install terraform aws-vault tfsec tflint docker docker-compose awscli pack
    @pip install checkov

    @just _alias_this
    @just install-hooks

# Install dependencies
[macos]
install:
    @brew install terraform aws-vault tfsec tflint docker docker-compose awscli buildpacks/tap/pack
    @pip install checkov

    @just _alias_this
    @just install-hooks

_alias_this:
    #!/usr/bin/env bash

    ALIAS_COMMAND="alias .j='just --justfile $(pwd)/justfile --'"

    if [ -n "$($SHELL -c 'echo $ZSH_VERSION')" ]; then
        if ! grep -q "$ALIAS_COMMAND" ~/.zshrc; then
            echo $ALIAS_COMMAND >> ~/.zshrc
        fi
    elif [ -n "$($SHELL -c 'echo $BASH_VERSION')" ]; then
        if [ -f ~/.bash_profile ]; then
            if ! grep -q "$ALIAS_COMMAND" ~/.bash_profile; then
                echo $ALIAS_COMMAND >> ~/.bash_profile
            fi
        else
            echo $ALIAS_COMMAND > ~/.bash_profile
        fi
    fi

# installs git hooks to run pre-commit checks
install-hooks:
    #!/usr/bin/env bash
    cp -r ./hooks ./.git
    chmod +x ./.git/hooks/*

# Add AWS config and aws-vault profile required to run many commands. Note: this will update .env file in current directory
add-profile profile:
    #!/usr/bin/env bash

    PROFILE=$(cat ~/.aws/config | grep "\[profile {{profile}}\]")
    
    if [ -z "$PROFILE" ]; then
        mfa_serial=$(cat ~/.aws/config | grep -m 1 mfa_serial | cut -d'=' -f2)
        account_id=$(read -p "Enter account id: " account_id; echo $account_id)
        role=$(read -p "Enter account role: " role; echo $role)

        echo "adding profile: {{profile}}"
        echo "[profile {{profile}}]" >> ~/.aws/config
        echo "role_arn=arn:aws:iam::$account_id:role/$role" >> ~/.aws/config
        echo "mfa_serial=$mfa_serial" >> ~/.aws/config
        echo "region=eu-west-2" >> ~/.aws/config
        echo "output=json" >> ~/.aws/config

        echo "profile {{profile}} added to ~/.aws/config"

        aws-vault add {{profile}}
        
    else
        echo "profile {{profile}} already exists"
    fi

    just _set-profile {{profile}}


# Set previously added aws-vault profile. Note: this will update .env file in current directory
set-profile profile:
    #!/usr/bin/env bash

    PROFILE=$(aws-vault list --profiles | grep {{profile}})

    if [ -z "$PROFILE" ]; then
        echo "profile {{profile}} does not exist. Run 'just add-profile {{profile}}' to add it."
    else
        just _set-profile {{profile}}
    fi


_set-profile profile:
    #!/usr/bin/env bash

    echo "setting current profile to {{profile}}"

    if [ -f .env ]; then
        sed -i -e 's/export AWS_PROFILE=.*$/export AWS_PROFILE={{profile}}/g' .env
    else
        echo export AWS_PROFILE={{profile}} > .env
    fi

    echo $(cat ~/.aws/config | grep -A 4 "\[profile {{profile}}\]")

[no-exit-message]
_ensure_aws_profile:
    #!/usr/bin/env bash

    if [[ -z "${AWS_PROFILE}" ]]; then
      echo "Please define your AWS_PROFILE environment variable, e.g. 'export AWS_PROFILE=integration'"
      exit 1
    fi

[no-exit-message]
_ensure_jq:
    #!/usr/bin/env bash

    if ! command -v jq &> /dev/null; then
      if [ "$(uname)" == "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
          echo "You need `jq` to run this just recipe. It can be installed using e.g. Homebrew."
          exit 1
        else
          echo "As this just recipe needs jq, installing it using Homebrew..."
          echo ""
          brew install jq
          echo ""
          echo "...jq installed using Homebrew - ready to run the just recipe!"
          echo ""
        fi
      else
        echo "You need `jq` available in your shell environment in order to run this just recipe. For installation, see https://stedolan.github.io/jq/"
        exit 1
      fi
    fi

# list available rds hosts
rds-list: _ensure_aws_profile
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws rds describe-db-instances --query 'DBInstances[*].Endpoint.Address' --output table
    echo "run 'just bastion-rds rds_endpoint=<endpoint>' to connect to the rds instance"

# Creates connection to RDS instance. requires bastion host 'bastion-host' to be running in currenct account. Run 'just rds-list' to get available endpoint addresses
rds-connect rds_endpoint local_port="5432": _ensure_aws_profile
    #!/usr/bin/env bash

    BASTION_RDS_INSTANCE_ID=$(aws-vault exec $AWS_PROFILE -- aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    
    echo "You can connect to your Database now using your preferred interface at server address localhost:{{local_port}}"
    echo "e.g. psql -h localhost -p 5432"
    echo "To connect, use username password stored in AWS Secrets Manager. You can see secrets by running 'just secrets-list'"
    echo "To stop the port forwarding session, run 'just rds-disconnect' or 'Ctrl + C'"
    
    aws-vault exec $AWS_PROFILE -- aws ssm start-session --target "$BASTION_RDS_INSTANCE_ID" --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="{{rds_endpoint}}",portNumber="5432",localPortNumber="{{local_port}}"

# Disconnects from RDS instance
rds-disconnect: _ensure_aws_profile
    #!/usr/bin/env bash
    BASTION_RDS_INSTANCE_ID=$(aws-vault exec $AWS_PROFILE -- aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    aws-vault exec $AWS_PROFILE -- aws ssm stop-session --target $(BASTION_RDS_INSTANCE_ID)

# list available secrets
secrets-list: _ensure_aws_profile
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws secretsmanager list-secrets --query 'SecretList[*].Name' --output table
    echo "You can view secrets by running: just get-secret {secret_name}"

# get secret value
get-secret secret_name: _ensure_aws_profile
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws secretsmanager get-secret-value --secret-id {{secret_name}} --query 'SecretString' --output text

# Runs tflint. Requires docker to be running
tflint:
    #!/usr/bin/env bash

    echo "running tflint..." 
    docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint --recursive

tfapply path=".": _ensure_aws_profile
    #!/usr/bin/env bash

    cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform apply

tfdestroy path="." force="false": _ensure_aws_profile
    #!/usr/bin/env bash

    if [ {{force}} = "false" ]; then
        echo "Make sure you consider the consequences and call me again with 'just tfdestroy path={{path}} force=true'"
    else
        echo "destroying infrastructure in {{path}}"
        cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform destroy
    fi

tfinit path="." backend="": _ensure_aws_profile
    #!/usr/bin/env bash

    if [ "{{backend}}" != "" ]; then
        echo "initialising terraform with backend {{backend}}"
        cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform init -backend-config={{backend}}
    else
        echo "initialising terraform"
        cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform init
    fi

# Updates tfvars file in S3 with values from local file. environment should be one of 'integration', 'staging' or 'production'
tfvars-put path="." environment="integration": _ensure_aws_profile
    #!/usr/bin/env bash

    cd {{path}} && aws-vault exec $AWS_PROFILE -- aws s3api put-object --bucket epbr-{{environment}}-terraform-state --key .tfvars --body {{environment}}.tfvars

#Updates tfvars file in S3 with values from local file. environment is 'ci'
tfvars-put-for-ci path="./ci": _ensure_aws_profile
    #!/usr/bin/env bash

    cd {{path}} && aws-vault exec $AWS_PROFILE -- aws s3api put-object --bucket epbr-terraform-state --key .tfvars --body .auto.tfvars

# Updates local tfvars file with values stored in S3 bucket. environment should be one of 'integration', 'staging' or 'production'
tfvars-get path="." environment="integration": _ensure_aws_profile
    #!/usr/bin/env bash

    cd {{path}}
    aws-vault exec $AWS_PROFILE -- aws s3api get-object --bucket epbr-{{environment}}-terraform-state --key .tfvars {{environment}}.tfvars
    cp {{environment}}.tfvars .auto.tfvars

# Updates local tfvars file for the ci with values stored in S3 bucket. environment is 'ci'
tfvars-get-for-ci path="./ci": _ensure_aws_profile
    #!/usr/bin/env bash

    cd {{path}}
    aws-vault exec $AWS_PROFILE -- aws s3api get-object --bucket epbr-terraform-state --key .tfvars .auto.tfvars

tfsec minimum_severity="HIGH":
    #!/usr/bin/env bash

    tfsec --minimum-severity {{minimum_severity}}

# Deploys docker image to ECR. Requires docker to be running. If dockerfile_path is not specified, it attempts to use existing image. dockerfile_path should be absolute path to directory containing dockerfile. Required for the toggles application or if you don't want to use a Paketo built image.
service-update-with-docker-image image_name service_name dockerfile_path="": _ensure_aws_profile
    #!/usr/bin/env bash

    set -e

    ECR_REPO_NAME={{service_name}}-ecr
    ACCOUNT_ID=$(aws-vault exec $AWS_PROFILE -- aws sts get-caller-identity --query Account --output text)

    docker login -u AWS -p $(aws-vault exec $AWS_PROFILE -- aws ecr get-login-password --region eu-west-2) $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com
    if [ "{{dockerfile_path}}" != "" ]; then
        docker buildx build --platform linux/amd64 -t {{image_name}} {{dockerfile_path}}
    fi
    docker tag {{image_name}}:latest $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest
    docker push $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest

    just service-refresh {{service_name}}

# Deploys paketo image to ECR. Requires both docker to be running and the pack CLI to be installed. If app_path is not specified, it attempts to use existing image. app_path should be absolute path to the root of the directory containing the application. For Paketo, uses the "full" Paketo builder by default unless specified (for the frontend app you should specify "base"), and likewise "web" for the default_process (for sidekiq you can specify "sidekiq" instead)
service-update-with-paketo-image image_name service_name app_path="" builder="full" default_process="web": _ensure_aws_profile
    #!/usr/bin/env bash

    ECR_REPO_NAME={{service_name}}-ecr
    ACCOUNT_ID=$(aws-vault exec $AWS_PROFILE -- aws sts get-caller-identity --query Account --output text)

    docker login -u AWS -p $(aws-vault exec $AWS_PROFILE -- aws ecr get-login-password --region eu-west-2) $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com
    if [ "{{app_path}}" != "" ]; then
        mv {{app_path}}/AWS-Procfile {{app_path}}/Procfile
        pack build {{image_name}} --buildpack paketo-buildpacks/ruby --path {{app_path}} --builder paketobuildpacks/builder:{{builder}} --default-process {{default_process}}
        pack_exit_code=$?
        mv {{app_path}}/Procfile {{app_path}}/AWS-Procfile
        if [[ pack_exit_code -ne 0 ]] ; then
            exit 1
        fi
    fi
    docker tag {{image_name}}:latest $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest
    docker push $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest

    just service-refresh {{service_name}}

fluentbit-update-image image_name dockerfile_path="": _ensure_aws_profile
    #!/usr/bin/env bash

    set -e

    ECR_REPO_NAME=fluentbit
    ACCOUNT_ID=$(aws-vault exec $AWS_PROFILE -- aws sts get-caller-identity --query Account --output text)

    docker login -u AWS -p $(aws-vault exec $AWS_PROFILE -- aws ecr get-login-password --region eu-west-2) $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com
    if [ "{{dockerfile_path}}" != "" ]; then
        docker buildx build --platform linux/amd64 -t {{image_name}} {{dockerfile_path}}
    fi
    docker tag {{image_name}}:latest $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest
    docker push $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest

# List services available in this context. These values can be used as a "service_name" parameter in some other tasks.
services-list: _ensure_aws_profile _ensure_jq
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws ecs list-clusters | jq -r '.clusterArns|map(split("/")[1])|map(split("-")[0:-1]|join("-"))|join("\n")'

# Force redeploy of ECS service. Do this to make parameter changes take effect
service-refresh service_name: _ensure_aws_profile
    #!/usr/bin/env bash

    ECS_CLUSTER_NAME={{service_name}}-cluster
    aws-vault exec $AWS_PROFILE -- aws ecs update-service --cluster $ECS_CLUSTER_NAME --service {{service_name}} --force-new-deployment

parameters-list: _ensure_aws_profile
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws ssm describe-parameters --query 'Parameters[*][Name, Type, LastModifiedDate]' --output table

# Should only be used for testing. For persisting change, update .tfvars instead
parameters-set name value: _ensure_aws_profile
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws ssm put-parameter --name {{name}} --value {{value}} --overwrite
    
    echo "Parameter update. To make changes take effect, run 'just refresh-service service_name=<service_name>'"

exec-cmd cluster task_id container: _ensure_aws_profile
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws ecs execute-command --cluster {{cluster}} --task {{task_id}}  --interactive --container {{container}}  --command "/bin/sh"

# Open a bash session on an ECS service
ecs-shell service_name: _ensure_aws_profile _ensure_jq
    #!/usr/bin/env bash

    echo "Preparing session on ECS..."
    ECS_TASK_ARN=$(aws-vault exec $AWS_PROFILE -- aws ecs list-tasks --cluster {{service_name}}-cluster | jq -r '.taskArns[0]')
    if [[ -z "${ECS_TASK_ARN}" ]]; then
      echo "No tasks are currently running associated with the service {{service_name}}"
      exit 1
    fi
    ECS_CONTAINER_NAME=$(aws-vault exec $AWS_PROFILE -- aws ecs describe-tasks --cluster {{service_name}}-cluster --tasks $ECS_TASK_ARN | jq -r '.tasks[0].containers|map(select(.name|contains("fluentbit")|not))[0].name')
    if [[ -z "${ECS_CONTAINER_NAME}" ]]; then
      echo "No containers are currently associated with the service {{service_name}}"
      exit 1
    fi
    aws-vault exec $AWS_PROFILE -- aws ecs execute-command --cluster {{service_name}}-cluster --task $ECS_TASK_ARN --interactive --container $ECS_CONTAINER_NAME --command "/usr/bin/env bash"
