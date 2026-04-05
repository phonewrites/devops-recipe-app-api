# Terraform – deployment setup (`infra/deploy`)

Application infrastructure: networking, ECS, RDS, load balancing, DNS, and related resources for the running API.

## GitHub Actions

### Variables

- `DOCKERHUB_USER` — Docker Hub user (image pulls).
- `OIDC_GH_ACTIONS_ROLE_MGMT` — role in the management account to assume into the workload account.
- `CICD_GH_ACTIONS_ROLE_PROD` — role in the workload account for GitHub Actions deploys.
- `ECR_APP_REPOSITORY_NAME` — ECR repo name for the app image (not the full URI).
- `ECR_PROXY_REPOSITORY_NAME` — ECR repo name for the proxy image.
- `TF_VAR_CUSTOM_DOMAIN` — custom domain for Terraform.

### Secrets

- `DOCKERHUB_TOKEN` — token for `DOCKERHUB_USER`.
- `TF_VAR_DB_PASSWORD` — RDS password.
- `TF_VAR_DJANGO_SECRET_KEY` — Django `SECRET_KEY`.

## Local format / validate (no backend)

From `infra/`:

```sh
docker compose run --rm terraform -chdir=deploy fmt
docker compose run --rm terraform -chdir=deploy validate
docker compose run --rm terraform -chdir=deploy init -backend=false
docker compose run --rm terraform -chdir=deploy init -upgrade -backend=false
```

You can format and validate without AWS credentials. Use `-backend=false` when you only need to refresh providers/lockfile without touching remote state.

## After ECS is running

- Use the task’s public IP (if assigned) and open:

  `http://[TASK_PUBLIC_IP]:8000/api/health-check/`  
  `http://[TASK_PUBLIC_IP]:8000/admin`  
  `http://[TASK_PUBLIC_IP]:8000/api/docs`

- The Session Manager plugin is required for `aws ecs execute-command`:

```sh
aws --profile prod ecs execute-command --region us-east-1 --cluster [CLUSTER_NAME] \
    --task [TASK_ID] \
    --container api \
    --interactive \
    --command "/bin/sh"
```

Inside the API container:

```sh
python manage.py createsuperuser
```

Then sign in at `http://[TASK_PUBLIC_IP]:8000/admin`.

## After an ALB exists

`http://[ALB_DNS_NAME]/api/health-check/`  
`http://[ALB_DNS_NAME]/admin`  
`http://[ALB_DNS_NAME]/api/docs`

## After EFS is configured

Re-test using the same URLs as above. If the deployment was recreated, the database may be empty — create a superuser again via `execute-command` as above.

## Custom domain and HTTPS

After DNS and certificate setup, test:

`http://[CUSTOM_SUB_DOMAIN_NAME]/api/health-check/`  
`http://[CUSTOM_SUB_DOMAIN_NAME]/admin`  
`http://[CUSTOM_SUB_DOMAIN_NAME]/api/docs`

---

Back to [infra overview](../README.md) · Previous: [bootstrap (`setup/`)](../setup/README.md)
