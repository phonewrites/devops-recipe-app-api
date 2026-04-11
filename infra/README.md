# Infrastructure (Terraform)

Run Terraform from `infra/` using compose service in [`docker-compose.yml`](docker-compose.yml) (`docker compose run --rm terraform …`). Compose mounts **`~/.aws`** (read-only); sign in first so the container can use your credentials.

**Two accounts:** Management vs workload (prod). [`setup/providers.tf`](setup/providers.tf) expects CLI profiles **`mgmt`** and **`prod`** in `~/.aws/config`.

**Order:** Part 1 (`setup/`) bootstrap, then Part 2 (`deploy/`) application stack.

## Part 1: Terraform – pre-deployment setup (`setup/`)

Resources here are bootstrap for the rest of the project: Terraform remote state, IAM for GitHub OIDC and CI/CD, ECR, and related policies.

### Remote state bucket (outside Terraform)

Create a bucket for Terraform state and turn on versioning (recommended for recovery in actual production environments). Block public access (default). Use the **same name** as `var.tf_state_bucket` in [`setup/variables.tf`](setup/variables.tf) and as `bucket` in the `backend "s3"` block in [`setup/providers.tf`](setup/providers.tf) (Terraform cannot plug variables into `backend`).

```sh
export ACCOUNT_ID=YOUR_MANAGEMENT_ACCOUNT_ID
export AWS_REGION=us-east-1
BUCKET="terraform-state-${ACCOUNT_ID}-${AWS_REGION}"
aws --profile mgmt --region "${AWS_REGION}" s3api create-bucket --bucket "${BUCKET}"
aws --profile mgmt --region "${AWS_REGION}" s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled
```

Use your **mgmt** account id; match the bucket name in **`setup/variables.tf`** and both **`backend "s3"`** blocks. Other regions: add `--create-bucket-configuration LocationConstraint=${AWS_REGION}` to `create-bucket`.

> Note: Terraform 1.14+ supports S3 native locking via `.tflock` files. DynamoDB is not required for state locking.

### Terraform commands (via Docker)

Run from the `infra/` directory, after AWS authentication (for example `aws sso login --sso-session YOUR_AWS_ORG_SESSION_NAME`):

```sh
docker compose run --rm terraform -chdir=setup init
docker compose run --rm terraform -chdir=setup fmt
docker compose run --rm terraform -chdir=setup validate
docker compose run --rm terraform -chdir=setup plan
docker compose run --rm terraform -chdir=setup apply
```

OIDC-based IAM roles are created as in the `.tf` files. Different GitHub repo: edit [`setup/iam_oidc_mgmt.tf`](setup/iam_oidc_mgmt.tf).

---

## Part 2: Application stack (`deploy/`)

Application infrastructure: networking, ECS, RDS, load balancing, DNS, and related resources for the running API.

**Deploy `plan` / `apply`:** use **GitHub Actions** ([workflow](../.github/workflows/deploy.yml): **`main`** → workspace `staging`, **`prod`** → `prod`). Locally: **`fmt`**, **`validate`**, **`init -backend=false`** only.

### GitHub Actions

Role ARNs come from IAM after Part 1 (`oidc-gh-actions-role` in **mgmt**, `cicd-gh-actions-role` in **prod**). Domain: public zone apex in **prod**.

#### Variables

- `DOCKERHUB_USER` — Docker Hub user (image pulls).
- `OIDC_GH_ACTIONS_ROLE_MGMT` — `oidc-gh-actions-role` ARN (**mgmt**).
- `CICD_GH_ACTIONS_ROLE_PROD` — `cicd-gh-actions-role` ARN (**prod**).
- `ECR_APP_REPOSITORY_NAME` — e.g. `recipe-app-api-app` (name only).
- `ECR_PROXY_REPOSITORY_NAME` — e.g. `recipe-app-api-proxy`.
- `TF_VAR_CUSTOM_DOMAIN` — e.g. `example.com` (prod public zone).

#### Secrets

- `DOCKERHUB_TOKEN` — token for `DOCKERHUB_USER`.
- `TF_VAR_DB_PASSWORD` — RDS password.
- `TF_VAR_DJANGO_SECRET_KEY` — Django `SECRET_KEY`.

### Local format / validate (no backend)

From `infra/`:

```sh
docker compose run --rm terraform -chdir=deploy fmt
docker compose run --rm terraform -chdir=deploy validate
docker compose run --rm terraform -chdir=deploy init -backend=false
docker compose run --rm terraform -chdir=deploy init -upgrade -backend=false
```

You can format and validate without AWS credentials. Use `-backend=false` when you only need to refresh providers/lockfile without touching remote state.

### After ECS is running

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

### After an ALB exists

`http://[ALB_DNS_NAME]/api/health-check/`  
`http://[ALB_DNS_NAME]/admin`  
`http://[ALB_DNS_NAME]/api/docs`

### After EFS is configured

Re-test using the same URLs as above. If the deployment was recreated, the database may be empty — create a superuser again via `execute-command` as above.

### Custom domain and HTTPS

After DNS and certificate setup, test:

`http://[CUSTOM_SUB_DOMAIN_NAME]/api/health-check/`  
`http://[CUSTOM_SUB_DOMAIN_NAME]/admin`  
`http://[CUSTOM_SUB_DOMAIN_NAME]/api/docs`