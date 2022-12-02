resource "aws_api_gateway_domain_name" "domain" {
  domain_name     = var.domain
  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = var.domain
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
}

#
# TLS Certificate
#
resource "aws_acm_certificate" "cert" {
    provider = aws.us-east-1
    domain_name       = var.domain
    validation_method = "DNS"

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us-east-1
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.validation.fqdn]
}

resource "aws_route53_zone" "primary" {
  name = var.domain
}

# Example DNS record using Route53.
# Route53 is not specifically required; any DNS host can be used.
resource "aws_route53_record" "route" {
  name    = var.domain
  type    = "A"
  zone_id = aws_route53_zone.primary.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.domain.cloudfront_zone_id
  }
}
resource "aws_route53_record" "validation" {
  allow_overwrite = true
  name =  tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  type = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id = aws_route53_zone.primary.zone_id
  ttl = 60
}