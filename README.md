# DevOps Deployment Automation with Terraform, AWS and Docker

Modified from [LondonAppDeveloper/devops-recipe-app-api](https://github.com/LondonAppDeveloper/devops-recipe-app-api).

Parts 1–2 below: local Docker (dev on port 8000, then nginx/Gunicorn on port 80). For AWS and Terraform, continue in [`infra/README.md`](infra/README.md) or jump to [Next: AWS & Terraform](#next-aws--terraform).

---

## Local demo (Docker)

### What you need

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose on Linux)
- This repository cloned and a terminal open at the project root

---

### Part 1: Local development stack (`docker-compose.yml`)

1. Start Postgres and Django (runserver):

```sh
docker compose up -d
```

`-d` keeps containers in the background.

2. Smoke-test the API in a browser:

[http://127.0.0.1:8000/api/health-check/](http://127.0.0.1:8000/api/health-check/)

3. Create a superuser (answer the prompts):

```sh
docker compose run --rm app sh -c "python manage.py createsuperuser"
```

4. Explore the app (all on port 8000):

   - Health: [http://127.0.0.1:8000/api/health-check/](http://127.0.0.1:8000/api/health-check/)
   - Admin: [http://127.0.0.1:8000/admin](http://127.0.0.1:8000/admin)
   - API docs: [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs)

   Use the admin and Swagger (token, recipes, images) as you like.

---

### Part 2: Local deployment-style stack (`docker-compose-deploy.yml`)

Same app with nginx → Gunicorn → Django. Only nginx is published to your machine — use **port 80** in the browser, not port 8000.

Do this after Part 1 when you want that layout.

1. Stop dev and remove volumes (and stray containers from other compose files):

```sh
docker compose down --volumes
docker compose down --volumes --remove-orphans
```

2. Provide env vars for compose interpolation (defaults are fine for a quick demo):

```sh
cp .env.sample .env
```

Use `127.0.0.1` in the browser, or add `localhost` to `DJANGO_ALLOWED_HOSTS` in `.env` if you prefer `http://localhost/...`.

3. Start the deploy stack:

```sh
docker compose -f docker-compose-deploy.yml up -d --build
```

4. Create a superuser:

```sh
docker compose -f docker-compose-deploy.yml run --rm app sh -c "python manage.py createsuperuser"
```

5. Open the app on port 80 only (not 8000):

   - Health: [http://127.0.0.1/api/health-check/](http://127.0.0.1/api/health-check/)
   - Admin: [http://127.0.0.1/admin](http://127.0.0.1/admin)
   - API docs: [http://127.0.0.1/api/docs](http://127.0.0.1/api/docs)

   Repeat the same checks as Part 1.

6. Clean up the local deployment-style stack (and stray containers from other compose files):

```sh
docker compose -f docker-compose-deploy.yml down --volumes
docker compose up -d
```

---

## Next: AWS & Terraform

1. [`infra/README.md`](infra/README.md) — hub: run docker compose from `infra/`, order is `setup/` then `deploy/`, plus a short CI/CD workflows overview (which GitHub Actions run on PR vs push).
2. Terraform pre-deployment setup: `terraform -chdir=setup`.
3. Terraform deployment setup: `terraform -chdir=deploy`.

---

## Major changes made to the original repo's code:
- Using an AWS organisation (multiple AWS accounts) setup, with a management account and one member account (prod) to simulate a real-world scenario. However, the code can be extended to support multiple member accounts.
- Using AWS Identity Center/SSO instead of IAM users for authentication.
- Using granted instead of aws-vault to use locally configured AWS credentials to authenticate an SSO User with Administrator access.
- Using IAM roles & chaining them from an AWS Management account to the account where the service is actually launched, instead of IAM users (with access keys & secrets, i.e. long-lived creds).
- Deployment of Networking configuration is extendable for an organisation with different network sizes, more than 2 tiers of subnets, etc.
- Deprecated resources are replaced with the latest ones, following the terraform recommeded best practices.
- Terraform code is DRY wherever possible, adding to the extendability from the point above.
- IAM permissions are updated to fix deployment workflow errors, espcially regarding the Service Linked Roles.
- Custom domain is passed at runtime via the environment using a GitHub Actions variable, instead of hardcoding it in the Terraform code.
- `docker-compose.yml` used for deployment is modified to work with the changes made above.
- On AWS ECS, material that must not appear as cleartext in the console is supplied via SSM `SecureString` parameters and ECS `secrets` instead of plain `environment` entries.


---

## Software Version Summary
- Python base image: `python:3.13-alpine3.23`
- Django: `5.2.x` LTS (longer support window; Python 3.10+)
- PostgreSQL: `17-alpine` (local compose)
- Nginx (proxy): `nginxinc/nginx-unprivileged:1.29.5-alpine3.23`
- Terraform: 1.14.8; AWS provider `~> 6.39.0`
- Other key packages:
    - djangorestframework: >=3.17,<3.18
    - drf-spectacular: >=0.29,<0.30
    - Pillow: >=12.2,<13
    - gunicorn: >=25.3,<26
    - flake8 (dev): >=7.3,<8.0
