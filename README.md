# DevOps Deployment Automation with Terraform, AWS and Docker 
Modified code from [LondonAppDeveloper/devops-recipe-app-api](https://github.com/LondonAppDeveloper/devops-recipe-app-api)


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

2.  Browse the Django admin at [http://127.0.0.1:8000/admin](http://127.0.0.1:8000/admin) and login. Browse the API docs at [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs) 

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
Login at [http://127.0.0.1/admin](http://127.0.0.1/admin)
Go to [http://127.0.0.1/api/docs](http://127.0.0.1/api/docs)

- After setting up Gunicorn related configs, rebuild to use new dockerfile/s
```
docker compose -f docker-compose-deploy.yml build
```

## Terraform Setup

These resources are created & managed outside Terraform & are used to store the Terraform state.
Create a bucket for storing Terraform state & enable versioning (highly recommended for state recovery). Ensure that public access is blocked; should be by default.
```
aws --profile mgmt s3api create-bucket --bucket tf-state-[REGION]-[ACCOUNT_ID] --create-bucket-configuration LocationConstraint=[REGION];
aws --profile mgmt s3api put-bucket-versioning --bucket tf-state-[REGION]-[ACCOUNT_ID] --versioning-configuration Status=Enabled
```

> **Note:** Terraform 1.14+ uses S3 native locking via `.tflock` files. DynamoDB tables are no longer required for state locking.

Run the common commands via Docker Compose
>Note: These  commands should be run from the infra/ directory of the project, and after authenticating with `aws sso login --sso-session YOUR_AWS_ORG_SESSION_NAME`
```
docker compose run --rm terraform -chdir=setup init
docker compose run --rm terraform -chdir=setup fmt
docker compose run --rm terraform -chdir=setup validate
docker compose run --rm terraform -chdir=setup plan
docker compose run --rm terraform -chdir=setup apply
```
Instead of using IAM users in AWS with access keys & secrets (long-lived creds), I use OICD passed IAM roles. The above terraform commands will create those.

## Terraform deploy setup

### GitHub Actions Variables
**Variables:**

`DOCKERHUB_USER`: Username for Docker Hub for avoiding Docker Pull rate limit issues.  
`OIDC_GH_ACTIONS_ROLE_MGMT`: Role in the management account that allows GitHub Actions to assume a role in the *prod* account.  
`CICD_GH_ACTIONS_ROLE_PROD`: Role in the *prod* account that allows GitHub Actions to perform deployments.  
`ECR_APP_REPOSITORY_NAME`: Name of the ECR repository for the app image *(not repository URI)*.  
`ECR_PROXY_REPOSITORY_NAME`: Name of the ECR repository for the proxy image *(not repository URI)*.  
`TF_VAR_CUSTOM_DOMAIN`: Custom domain name for the application, passed as an environment variable to the Terraform code.

**Secrets:**

`DOCKERHUB_TOKEN`: Token created in DOCKERHUB_USER in Docker Hub.  
`TF_VAR_DB_PASSWORD`: Password for the RDS database (make something up).  
`TF_VAR_DJANGO_SECRET_KEY`: Secret key for the Django app (make something up).  


- Run the following commands to confirm if the terraform code is valid and formatted correctly before pushing to the repo.
    ```
    docker compose run --rm terraform -chdir=deploy fmt
    docker compose run --rm terraform -chdir=deploy validate
    docker compose run --rm terraform -chdir=deploy init -backend=false
    docker compose run --rm terraform -chdir=deploy init -upgrade -backend=false
    ```
>Note: You can format & validate the deploy terraform stack locally without any issues. Use the backend=false flag to update the lock file without needing AWS credentials for regular init or version upgrades.   
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
- *Set up a custom sub domain & https certificate.* Then, test again using above URLs in the browser:
    `http://[CUSTOM_SUB_DOMAIN_NAME]/api/health-check/`  
    `http://[CUSTOM_SUB_DOMAIN_NAME]/admin`  
    `http://[CUSTOM_SUB_DOMAIN_NAME]/api/docs`


## Major changes made to the original repo's code:
- Using an AWS organisation (multiple AWS accounts) setup, with a management account and one member account (prod) to simulate a real-world scenario. However, the code can be extended to support multiple member accounts.
- Using AWS Identity Center/SSO instead of IAM users for authentication.
- Using granted instead of aws-vault to use locally configured AWS credentials to authenticate an SSO User with Administrator access.
- Using IAM roles & chaining them from an AWS Management account to the account where the service is actually launched, instead of IAM users (with access keys & secrets, i.e. long-lived creds).
- Deployment of Networking configuration is extendable for an organisation with different network sizes, more than 2 tiers of subnets, etc.
- Deprecated resources are replaced with the latest ones, following the terraform recommeded best practices.
- Terraform code is DRY wherever possible, adding to the extendability from the point above.
- IAM permissions are updated to fix deployment workflow errors, espcially regarding the Service Linked Roles.
- Custom domain is passed at runtime via the environment using GitHub-Actions a variable, instead of hardcoding it in the Terraform code.
- `docker-compose.yml` used for deployment is modified to work with the changes made above.