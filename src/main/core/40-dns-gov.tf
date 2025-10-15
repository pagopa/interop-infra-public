resource "aws_route53_zone" "api_gov_public" {
  count = var.dns_api_gov_domain != null ? 1 : 0

  name = var.dns_api_gov_domain
}

resource "aws_route53_zone" "interop_gov_public" {
  count = var.dns_interop_gov_domain != null ? 1 : 0

  name = var.dns_interop_gov_domain
}

resource "aws_route53_zone" "pdnd_gov_public" {
  count = var.dns_pdnd_gov_domain != null ? 1 : 0

  name = var.dns_pdnd_gov_domain
}
