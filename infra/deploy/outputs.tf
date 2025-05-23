output "api_endpoint" {
  value = aws_route53_record.app_cname_record.fqdn
}