# Terraform – pre-deployment setup (`infra/setup`)

Resources here are bootstrap for the rest of the project: Terraform remote state, IAM for GitHub OIDC and CI/CD, ECR, and related policies.

## Remote state bucket (outside Terraform)

Create a bucket for Terraform state and turn on versioning (recommended for recovery). Block public access (default).

```text
aws --profile mgmt s3api create-bucket --bucket tf-state-[REGION]-[ACCOUNT_ID] --create-bucket-configuration LocationConstraint=[REGION];
aws --profile mgmt s3api put-bucket-versioning --bucket tf-state-[REGION]-[ACCOUNT_ID] --versioning-configuration Status=Enabled
```

> Note: Terraform 1.14+ supports S3 native locking via `.tflock` files. DynamoDB is not required for state locking.

## Terraform commands (via Docker)

Run from the `infra/` directory, after AWS authentication (for example `aws sso login --sso-session YOUR_AWS_ORG_SESSION_NAME`):

```sh
docker compose run --rm terraform -chdir=setup init
docker compose run --rm terraform -chdir=setup fmt
docker compose run --rm terraform -chdir=setup validate
docker compose run --rm terraform -chdir=setup plan
docker compose run --rm terraform -chdir=setup apply
```

OIDC-based IAM roles (instead of long-lived access keys) are created by this stack as configured in the `.tf` files here.

---

Back to [infra overview](../README.md) · Next: [deployment stack (`deploy/`)](../deploy/README.md)
