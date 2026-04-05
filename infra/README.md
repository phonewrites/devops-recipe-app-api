# Infrastructure (Terraform)

Run Terraform from `infra/` using compose service in [`docker-compose.yml`](docker-compose.yml) (`docker compose run --rm terraform …`). Sign in to AWS first.

Order: `setup/` (bootstrap), then `deploy/` (running app).

- [setup/README.md](setup/README.md) — remote state, IAM / OIDC / CI/CD, ECR, backend access (`-chdir=setup`).
- [deploy/README.md](deploy/README.md) — VPC, ECS, RDS, load balancer, DNS (`-chdir=deploy`).
