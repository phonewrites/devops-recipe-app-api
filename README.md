# DevOps Deployment Automation with Terraform, AWS and Docker - Starter Code

## Local Development

### Running Project

This project runs using Docker. It should work consistently on Windows, macOS or Linux machines.

Follow the below steps to run a local development environment.

1.  Ensure you have the following installed:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

2.  Clone the project, `cd` to it in Terminal/Command Prompt and run the following:

```sh
docker compose up -d
```
>I prefer the -d flag to run it in detached mode. Optional.

3.  Browse the project at [http://127.0.0.1:8000/api/health-check/](http://127.0.0.1:8000/api/health-check/)

### Creating Superuser

To create a superuser to access the Django admin follow these steps.

1.  Run the below command and follow the instructions in terminal:
```sh
docker compose run --rm app sh -c "python manage.py createsuperuser"
```
>Use `--rm` flag to ensure that the temporary `app` service container does not persist in your system (in a stopped state)

2.  Browse the Django admin at `http://127.0.0.1:8000/admin` and login. Browse the API docs at `http://127.0.0.1:8000/api/docs` 

### Clearing Storage

To clear all storage (including the database) and start fresh:
```sh
docker compose down --volumes
```

- Do the same to test the deployment-specific file
```sh
docker compose -f docker-compose-deploy.yml up -d
```
```sh
docker compose -f docker-compose-deploy.yml run --rm app sh -c "python manage.py createsuperuser"
```
Login at `http://127.0.0.1/admin`
Go to `http://127.0.0.1/api/docs`

- After setting up Gunicorn related configs, rebuild to use new dockerfile/s
```
docker compose -f docker-compose-deploy.yml build
```

## Terraform Setup
These resources are created & managed outside Terraform & are used to store the Terraform state.
Create a bucket for storing Terraform state & enable versioning (Check if public access is blocked; should be by default)
```
aws --profile mgmt s3api create-bucket --bucket tf-state-[REGION]-[ACCOUNT_ID];
aws --profile mgmt s3api put-bucket-versioning --bucket tf-state-[REGION]-[ACCOUNT_ID] --versioning-configuration Status=Enabled
```
Create a Dynamo-DB table with Partition key attribute `LockID` for state locking.
```
aws --profile mgmt dynamodb create-table --table-name "terraform-state-locks" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=3,WriteCapacityUnits=3
```

Run the common commands via Docker Compose
>Note: These  commands should be run from the infra/ directory of the project, and after authenticating with `aws sso login --sso-session YOUR_AWS_ORG_SESSION_NAME`
```
docker compose run --rm terraform -chdir=setup fmt
docker compose run --rm terraform -chdir=setup validate
docker compose run --rm terraform -chdir=setup plan
docker compose run --rm terraform -chdir=setup apply
```
Instead of using IAM users in AWS with access keys & secrets (long-lived creds), I use OICD passed IAM roles. The above terraform commands will create those.

## Terraform deploy setup
- Run the following commands to confirm if the terraform code is valid and formatted correctly before pushing to the repo.
    ```
    docker compose run --rm terraform -chdir=setup fmt
    docker compose run --rm terraform -chdir=setup validate
    ```
- After *ECS servcie is running successfully*, copy your ECS service task's Public IP address & access the deployed app by browsing the following URLs:
    `http://[TASK_PUBLIC_IP]:8000/api/health-check/`  
    `http://[TASK_PUBLIC_IP]:8000/admin`  
    `http://[TASK_PUBLIC_IP]:8000/api/docs`  

- Ensure that AWS SessionManager plugin is installed on your local machine. This is required to run `aws ecs execute-command`:
    ```
    aws --profile prod ecs execute-command --region us-east-1 --cluster [CLUSTER_NAME] \
        --task [TASK_ID]\
        --container api \
        --interactive \
        --command "/bin/sh"
    ```
- Once inside the task's API container, run the following command to create a superuser:
    ```
    python manage.py createsuperuser
    ```
    Test by logging into the Django admin at `http://[TASK_PUBLIC_IP]:8000/admin` with the superuser credentials you just created.
- After *setting up a ALB* in front of the ECS service, test accessing the app via the ALB's DNS name:  
    `http://[ALB_DNS_NAME]/api/health-check/`  
    `http://[ALB_DNS_NAME]/admin`  
    `http://[ALB_DNS_NAME]/api/docs`
- After *setting up EFS* for persistent storage, test again using above URLs in the browser. If the entire deployment was deleted and recreated, the database will be empty. You can create a superuser again using the command:
    ```
    aws --profile prod ecs execute-command --region us-east-1 --cluster [CLUSTER_NAME] \
        --task [TASK_ID]\
        --container api \
        --interactive \
        --command "/bin/sh"
    python manage.py createsuperuser
    ```






## Major changes compared to the original course code:
- Using an AWS organisation (multiple AWS accounts) setup, with a management account and one member account (prod) to simulate a real-world scenario. However, the code can be extended to support multiple member accounts.
- Using AWS Identity Center/SSO instead of IAM users for authentication.
- Using granted instead of aws-vault to use locally configured AWS credentials to authenticate an SSO User with Administrator access.
- Using IAM roles & chaining them from an AWS Management account to the account where the service is actually launched, instead of IAM users (with access keys & secrets, i.e. long-lived creds).
- Consolidated all IAM permissions needed by the main CICD role into a single policy, instead of having multiple policies for each service.
- Deployment of Networking configuration is extendable for an organisation with different network sizes, more than 2 tiers of subnets, etc.
- Deprecated resources are replaced with the latest ones, following the terraform recommeded best practices.
- Terraform code is DRY wherever possible, adding to the extendability from the point above.
- IAM permissions updated, espcially regarding the Service Linked Roles for RDS & ECS.
- docker-compose files are modified to work with the changes made above.






Sources:
https://github.com/github/gitignore/blob/main/Terraform.gitignore



############# MY EDITS TILL HERE #####



## Course Documentation

This section contains supplementary documentation for the course steps.

### AWS CLI

#### AWS CLI Authentication

This course uses [aws-vault](https://github.com/99designs/aws-vault) to authenticate with the AWS CLI in the terminal.

To authenticate:

```
aws-vault exec PROFILE --duration=8h
```

Replace `PROFILE` with the name of the profile.

To list profiles, run:

```
aws-vault list
```

#### Task Exec

[ECS Exec](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html) is used for manually running commands directly on the running containers.

To get shell access to the `ecs` task:

```
aws ecs execute-command --region REGION --cluster CLUSTER_NAME --task TASK_ID --container CONTAINER_NAME --interactive --command "/bin/sh"
```

Replace the following values in the above command:

- `REGION`: The AWS region where the ECS cluster is setup.
- `CLUSTER_NAME`: The name of the ECS cluster.
- `TASK_ID`: The ID of the running ECS task which you want to connect to.
- `CONTAINER_NAME`: The name of the container to run the command on.

### Terraform Commands

Below is a list of how to run the common commands via Docker Compose.

> Note: The below commands should be run from ther `infra/` directory of the project, and after authenticating with `aws-vault`.

To run any Terraform command through Docker, use the syntax below:

```
docker compose run --rm terraform -chdir=TF_DIR COMMAND
```

Where `TF_DIR` is the directory containing the Terraform (`setup` or `deploy`) and `COMMAND` is the Terraform command (e.g. `plan`).

#### Get outputs from the setup Terraform

```
docker compose run --rm terraform -chdir=setup output
```

The output name must be specified if `sensitive = true` in the output definition, like this:

```
docker compose run --rm terraform -chdir=setup output cd_user_access_key_secret
```

### GitHub Actions Variables

This section lists the GitHub Actions variables which need to be configured on the GitHub project.

> Note: This is only applicable if using GitHub Actions, if you're using GitLab, see [GitLab CI/CD Variables](#gitlab-cicd-variables) below.

If using GitHub Actions, variables are set as either **Variables** (clear text and readable) or **Secrets** (values hidden in logs).

Variables:

- `AWS_ACCESS_KEY_ID`: Access key for the CD AWS IAM user that is created by Terraform and output as `cd_user_access_key_id`.
- `AWS_ACCOUNT_ID`: AWS Account ID taken from AWS directly.
- `DOCKERHUB_USER`: Username for [Docker Hub](https://hub.docker.com/) for avoiding Docker Pull rate limit issues.
- `ECR_REPO_APP`: URL for the Docker repo containing the app image output by Terraform as `ecr_repo_app`.
- `ECR_REPO_PROXY`: URL for the Docker repo containing the proxy image output by Terraform as `ecr_repo_proxy`.

Secrets:

- `AWS_SECRET_ACCESS_KEY`: Secret key for `AWS_ACCESS_KEY_ID` set in variables, output by Terraform as `cd_user_access_key_secret`.
- `DOCKERHUB_TOKEN`: Token created in `DOCKERHUB_USER` in [Docker Hub](https://hub.docker.com/).
- `TF_VAR_DB_PASSWORD`: Password for the RDS database (make something up).
- `TF_VAR_DJANGO_SECRET_KEY`: Secret key for the Django app (make something up).

### GitLab CI/CD Variables

This section lists the GitLab CI/CD variables which must be configured to run jobs.

> Note: This is only applicable if you are using GitLab CI/CD. If you are using GitHub Actions, see [#github-actions-variables](GitHub Actions Variables) above.

In GitLab CI/CD, all variables are set under **Variables**, and optionally set as masked (secrets hidden from output) and/or protected (restricted to protected branches).

Each variable and their state is listed below:

- `AWS_ACCESS_KEY_ID`: Access key for the CD AWS IAM user that is created by Terraform and output as `cd_user_access_key_id`.
- `AWS_ACCOUNT_ID`: AWS Account ID taken from AWS directly.
- `DOCKERHUB_USER`: Username for [Docker Hub](https://hub.docker.com/) for avoiding Docker Pull rate limit issues.
- `ECR_REPO_APP`: URL for the Docker repo containing the app image output by Terraform as `ecr_repo_app`.
- `ECR_REPO_PROXY`: URL for the Docker repo containing the proxy image output by Terraform as `ecr_repo_proxy`.
- `AWS_SECRET_ACCESS_KEY` (**Masked**): Secret key for `AWS_ACCESS_KEY_ID` set in variables, output by Terraform as `cd_user_access_key_secret`.
- `DOCKERHUB_TOKEN` (**Masked**): Token created in `DOCKERHUB_USER` in [Docker Hub](https://hub.docker.com/).
- `TF_VAR_db_password` (**Masked**): Password for the RDS database (make something up).
- `TF_VAR_django_secret_key` (**Masked**, **Protected**): Secret key for the Django app (make something up).

## Section Notes and Resources

### Software Requirements

#### Checking Each Dependency

Check docker is running:

```sh
docker --version
```

Check aws-vault installed:

```sh
aws-vault --version
```

Check AWS CLI:

```sh
aws --version
```

Check AWS CLI Systems Manager:

```sh
session-manager-plugin
```

Check docker compose:

```sh
docker compose --version
```

Configure Git:

```sh
git config --global user.email email@example.com
git config --global user.name "User Name" 
git config --global push.autoSetupRemote true
```
