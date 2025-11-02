# Changelog

All notable changes are documented here following [Keep a Changelog](https://keepachangelog.com/) conventions.

## [2025-11-02]
### Changed
- Upgrade Python base image in Dockerfile from `3.9-alpine3.13` to `3.11-alpine3.19`🎉
- Django upgraded to `4.2 LTS`
- djangorestframework upgraded to `>=3.14.0,<3.15`
- drf-spectacular upgraded to `>=0.27.0,<0.28`
- Pillow upgraded to `>=10.0.0,<11.0`
- gunicorn upgraded to `>=21.2.0,<22.0`
- flake8 (dev) upgraded to `>=7.0.0,<8.0`
- PostgreSQL upgraded from `13-alpine` to `16-alpine`
- Nginx upgraded from `1-alpine` to `1.29.2-alpine`
- Upgraded Terraform AWS provider to `6.19.0` 🚧😎
- Docker GitHub Actions (checkout, build-push, login, credentials) upgraded to latest versions for improved pipeline security and reliability

### Deprecated
- **Removed all resources & references to DynamoDB state lock (backend state):** Now uses S3 lockfile (`use_lockfile = true`) for Terraform locking 🚧([see commit](https://github.com/phonewrites/devops-recipe-app-api/commit/463a1909c718f820428c49f1f2e9218624cbdb3b))

### Changed
- **RDS DB storage type**: Upgraded from `gp2` to `gp3`

---

*See commit log for more details or changes to test paths, deployment conditions, etc.*
