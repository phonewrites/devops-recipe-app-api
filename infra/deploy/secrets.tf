# SSM SecureString parameters encrypted with the CMK created during setup
## When managed secret rotation needed ⇒ AWS Secrets Manager (ECS/RDS integration)

data "aws_kms_alias" "alias_secrets" {
  name = "alias/${var.project}/secrets"
}

resource "aws_ssm_parameter" "django_secret_key" {
  name        = "/${local.prefix}/django-secret-key"
  description = "Django SECRET_KEY for ${local.prefix}"
  type        = "SecureString"
  key_id      = data.aws_kms_alias.alias_secrets.target_key_id
  value       = var.django_secret_key
  tags = {
    Name = "/${local.prefix}/django-secret-key"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${local.prefix}/db-password"
  description = "RDS password for ${local.prefix} (mirrors TF/RDS; rotate both together if changed outside TF)"
  type        = "SecureString"
  key_id      = data.aws_kms_alias.alias_secrets.target_key_id
  value       = var.db_password
  tags = {
    Name = "/${local.prefix}/db-password"
  }
}