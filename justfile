set dotenv-load

default:
    @just --list
  
[windows]
install:
    @choco install terraform aws-vault tfsec tflint docker docker-compose awscli

[macos]
install:
    @brew install terraform aws-vault tfsec tflint docker docker-compose awscli

add-profile profile:
    #!/usr/bin/env bash

    profile=$(cat ~/.aws/config | grep "\[profile {{profile}}\]")
    
    if [ -z "$profile" ]; then
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


set-profile profile:
    #!/usr/bin/env bash

    profile=$(aws-vault list --profiles | grep {{profile}})
    if [ -z "$profile" ]; then
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

rds-list:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws rds describe-db-instances --query 'DBInstances[*].Endpoint.Address' --output table
    echo "run 'just bastion-rds rds_endpoint=<endpoint>' to connect to the rds instance"

# Creates SSM session connecting to RDS instance. requires bastion host 'bastion-host' to be running in currenct account
# run 'just rds-list' to get available endpoint addresses
# To connect, use username password stored in AWS Secrets Manager. You can see secrets by running 'just list-secrets'
rds-connect rds_endpoint local_port="5432":
    #!/usr/bin/env bash
    export BASTION_RDS_INSTANCE_ID=$(aws-vault exec $AWS_PROFILE -- aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    
    echo "You can connect to your Database now using your preferred interface at server address localhost:{{local_port}}"
    echo "e.g. psql -h localhost -p 5432"
    echo "To stop the port forwarding session, run 'just rds-disconnect' or 'Ctrl + C'"
    
    aws-vault exec $AWS_PROFILE -- aws ssm start-session --target $BASTION_RDS_INSTANCE_ID --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="{{rds_endpoint}}",portNumber="5432",localPortNumber="{{local_port}}"

rds-disconnect:
    #!/usr/bin/env bash
    export BASTION_RDS_INSTANCE_ID=$(aws-vault exec $AWS_PROFILE -- aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query 'Reservations[*].Instances[*].InstanceId' --output text)
    aws-vault exec $AWS_PROFILE -- aws ssm stop-session --target $(BASTION_RDS_INSTANCE_ID)

list-secrets:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws secretsmanager list-secrets --query 'SecretList[*].Name' --output table
    echo "You can view secrets by running: just get-secret {secret_name}"

get-secret secret_name:
    #!/usr/bin/env bash
    aws-vault exec $AWS_PROFILE -- aws secretsmanager get-secret-value --secret-id {{secret_name}} --query 'SecretString' --output text

update-tfvars:
    #!/usr/bin/env bash

    aws-vault exec $AWS_PROFILE -- aws s3 cp s3://$(TFVARS_BUCKET)/$(TFVARS_FILE) $(TFVARS_FILE)


tflint:
    #!/usr/bin/env bash

    echo "running tflint..." 
    docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint --recursive


tfapply path="service-infrastructure":
    #!/usr/bin/env bash

    cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform apply


tfinit path=".":
    #!/usr/bin/env bash

    cd {{path}} && aws-vault exec $AWS_PROFILE -- terraform init


tfsec minimum_severity="HIGH":
    #!/usr/bin/env bash

    tfsec --minimum-severity {{minimum_severity}}


deploy-to-ecr image_name ecr_repo_name:
    #!/usr/bin/env bash

    ACCOUNT_ID=$(aws-vault exec $AWS_PROFILE -- aws sts get-caller-identity --query Account --output text)

    docker login -u AWS -p $(aws-vault exec $(AWS_PROFILE) -- aws ecr get-login-password --region eu-west-2) $(ACCOUNT_ID).dkr.ecr.eu-west-2.amazonaws.com
    docker buildx build --platform linux/arm64 --t {{image_name}} .
    docker tag {{image_name}}:latest $(ACCOUNT_ID).dkr.ecr.eu-west-2.amazonaws.com/{{ecr_repo_name}}:latest
    docker push $(ACCOUNT_ID).dkr.ecr.eu-west-2.amazonaws.com/{{ecr_repo_name}}:latest
