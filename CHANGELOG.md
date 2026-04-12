# Changelog

All notable changes are documented here following [Keep a Changelog](https://keepachangelog.com/) conventions.

## [2026-04-12]
### Changed
- ECS: Django `SECRET_KEY` + DB password from SSM `SecureString` via `secrets`; CMK in `infra/setup` (`alias/<project>/secrets`); execution role + CI IAM for SSM/KMS
- GitHub Actions (deploy): `mask-aws-account-id` on both `configure-aws-credentials` steps
- CI `cicd_gha_*` IAM: extra SSM policy; tighter `recipe-api-*` ARNs where resource-level permissions exist

## [2026-04-11]
### Changed
- Python base image: `3.11-alpine3.19` → `3.13-alpine3.23`
- Django: `4.2 LTS` → `5.2.x` **LTS** (security/feature updates with extended support through April 2028)
- djangorestframework, drf-spectacular, Pillow, gunicorn, psycopg2, flake8 bumped to current stable compatible ranges (see `requirements.txt`)
- PostgreSQL (compose): `16-alpine` → `17-alpine`
- Nginx unprivileged proxy: `1.29.2-alpine` → `1.29.5-alpine3.23`
- `docker-compose-deploy.yml`: explicit **`deploy`** bridge network for `app`, `db`, and `proxy` so `docker compose run` one-off containers resolve the hostname **`db`** reliably
- Terraform (Docker image): `1.14.0-rc1` → `1.14.8`
- Terraform `required_version` in `infra/setup` and `infra/deploy`: `>= 1.14.8, < 2.0.0`
- Terraform AWS provider: `6.19.0` → `~> 6.39.0`
- GitHub Actions (checkout, build-push, login, credentials) upgraded to latest versions for improved pipeline security and reliability

## [2025-11-02]
### Changed
- Upgrade Python base image in Dockerfile from `3.9-alpine3.13` → `3.11-alpine3.19`🎉
- Django upgraded to `4.2 LTS`
- djangorestframework upgraded to `>=3.14.0,<3.15`
- drf-spectacular upgraded to `>=0.27.0,<0.28`
- Pillow upgraded to `>=10.0.0,<11.0`
- gunicorn upgraded to `>=21.2.0,<22.0`
- flake8 (dev) upgraded to `>=7.0.0,<8.0`
- PostgreSQL upgraded from `13-alpine` → `16-alpine`
- Nginx upgraded from `1-alpine` → `1.29.2-alpine`
- Upgraded Terraform AWS provider to `6.19.0` 🚧😎
- GitHub Actions (checkout, build-push, login, credentials) upgraded to latest versions for improved pipeline security and reliability

### Deprecated
- **Removed all resources & references to DynamoDB state lock (backend state):** Now uses S3 lockfile (`use_lockfile = true`) for Terraform locking 🚧([see commit](https://github.com/phonewrites/devops-recipe-app-api/commit/463a1909c718f820428c49f1f2e9218624cbdb3b))

### Changed
- **RDS DB storage type**: Upgraded from `gp2` → `gp3`

---

*See commit log for more details or changes to test paths, deployment conditions, etc.*
