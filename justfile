set dotenv-load

# List available commands
default:
    @just --list

# Install dependencies
[windows]
install:
    @choco install terraform aws-vault tfsec tflint docker docker-compose awscli
    
    @just _alias_this

# Install dependencies
[macos]
install:
    @brew install terraform aws-vault tfsec tflint docker docker-compose awscli

    @just _alias_this

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

# list available rds hosts
rds-list:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws rds describe-db-instances --query 'DBInstances[*].Endpoint.Address' --output table
    echo "run 'just bastion-rds rds_endpoint=<endpoint>' to connect to the rds instance"

# Creates connection to RDS instance. requires bastion host 'bastion-host' to be running in currenct account. Run 'just rds-list' to get available endpoint addresses
rds-connect rds_endpoint local_port="5432":
    #!/usr/bin/env bash
    BASTION_RDS_INSTANCE_ID=$(aws-vault exec $AWS_PROFILE -- aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    
    echo "You can connect to your Database now using your preferred interface at server address localhost:{{local_port}}"
    echo "e.g. psql -h localhost -p 5432"
    echo "To connect, use username password stored in AWS Secrets Manager. You can see secrets by running 'just list-secrets'"
    echo "To stop the port forwarding session, run 'just rds-disconnect' or 'Ctrl + C'"
    
    aws-vault exec $AWS_PROFILE -- aws ssm start-session --target $BASTION_RDS_INSTANCE_ID --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="{{rds_endpoint}}",portNumber="5432",localPortNumber="{{local_port}}"

# Disconnects from RDS instance
rds-disconnect:
    #!/usr/bin/env bash
    BASTION_RDS_INSTANCE_ID=$(aws-vault exec $AWS_PROFILE -- aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    aws-vault exec $AWS_PROFILE -- aws ssm stop-session --target $(BASTION_RDS_INSTANCE_ID)

# list available secrets
secrets-list:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws secretsmanager list-secrets --query 'SecretList[*].Name' --output table
    echo "You can view secrets by running: just get-secret {secret_name}"

# get secret value
get-secret secret_name:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws secretsmanager get-secret-value --secret-id {{secret_name}} --query 'SecretString' --output text

# Unimplemented. Updates local tfvars file with values from S3
tfvars-pull:
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws s3 cp s3://$TFVARS_BUCKET/$TFVARS_FILE $TFVARS_FILE

# Unimplemented. Updates S3 tfvars file with values from local file
tfvars-push:
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws s3 cp $TFVARS_FILE s3://$TFVARS_BUCKET/$TFVARS_FILE

# Runs tflint. Requires docker to be running
tflint:
    #!/usr/bin/env bash

    echo "running tflint..." 
    docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint --recursive

tfapply path=".":
    #!/usr/bin/env bash

    cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform apply

tfdestroy path="." force="false":
    #!/usr/bin/env bash
    if [ {{force}} = "false" ]; then
        echo "Make sure you consider the consequences and call me again with 'just tfdestroy path={{path}} force=true'"
    else
        echo "destroying infrastructure in {{path}}"
        cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform destroy
    fi

tfinit path="." backend="":
    #!/usr/bin/env bash
    if [ "{{backend}}" != "" ]; then
        echo "initialising terraform with backend {{backend}}"
        cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform init -backend-config={{backend}}
    else
        echo "initialising terraform"
        cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform init
    fi

tfsec minimum_severity="HIGH":
    #!/usr/bin/env bash

    tfsec --minimum-severity {{minimum_severity}}

# Deploys local image to ECR. Requires docker to be running. If dockerfile_path is not specified, it attempt to use existing image. dockerfile_path should be absolute path to directory containing dockerfile
service-update-image image_name service_name dockerfile_path="":
    #!/usr/bin/env bash

    ECR_REPO_NAME={{service_name}}-ecr
    ACCOUNT_ID=$(aws-vault exec $AWS_PROFILE -- aws sts get-caller-identity --query Account --output text)

    docker login -u AWS -p $(aws-vault exec $AWS_PROFILE -- aws ecr get-login-password --region eu-west-2) $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com
    if [ "{{dockerfile_path}}" != "" ]; then
        docker buildx build --platform linux/arm64 -t {{image_name}} {{dockerfile_path}}
    fi
    docker tag {{image_name}}:latest $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest
    docker push $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest

    just service-refresh {{service_name}}

fluentbit-update-image image_name dockerfile_path="":
    #!/usr/bin/env bash

    ECR_REPO_NAME=fluentbit
    ACCOUNT_ID=$(aws-vault exec $AWS_PROFILE -- aws sts get-caller-identity --query Account --output text)

    docker login -u AWS -p $(aws-vault exec $AWS_PROFILE -- aws ecr get-login-password --region eu-west-2) $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com
    if [ "{{dockerfile_path}}" != "" ]; then
        docker buildx build --platform linux/arm64 -t {{image_name}} {{dockerfile_path}}
    fi
    docker tag {{image_name}}:latest $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest
    docker push $ACCOUNT_ID.dkr.ecr.eu-west-2.amazonaws.com/$ECR_REPO_NAME:latest


# Force redeploy of ECS service. Do this to make parameter changes take effect
service-refresh service_name:
    #!/usr/bin/env bash

    ECS_CLUSTER_NAME={{service_name}}-cluster
    aws-vault exec integration -- aws ecs update-service --cluster $ECS_CLUSTER_NAME --service {{service_name}} --force-new-deployment

parameters-list:
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws ssm describe-parameters --query 'Parameters[*][Name, Type, LastModifiedDate]' --output table

parameters-set name value:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws ssm put-parameter --name {{name}} --value {{value}} --overwrite
    
    echo "Paramter update. To make changes take effect, run 'just refresh-service service_name=<service_name>'"
