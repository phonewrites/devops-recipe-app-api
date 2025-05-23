# Custom domain's hosted zone is set up in Route53 outside Terraform
data "aws_route53_zone" "public_zone" {
  name = "${var.dns_zone_name}."
}

resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.public_zone.name}"
  type    = "CNAME"
  records = [aws_lb.api.dns_name]
  ttl     = "60"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = aws_route53_record.cname_record.name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public_zone.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}