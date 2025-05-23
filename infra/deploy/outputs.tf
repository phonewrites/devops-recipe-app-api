output "api_endpoint" {
  value = aws_route53_record.cname_record.fqdn
}