data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_origin_access_control" "landing_s3" {
  name                              = "InteropLandingOAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "public_catalog" {
  name = "PublicCatalogCaching"

  min_ttl     = 0
  default_ttl = 3540 # 59 minutes
  max_ttl     = 3540 # 59 minutes

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_distribution" "landing" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = format("Interop landing page - %s", var.env)
  default_root_object = "index.html"
  wait_for_deployment = false

  aliases = [
    var.interop_landing_domain_name,
    "www.${var.interop_landing_domain_name}"
  ]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.landing.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  origin {
    origin_id                = "S3FrontendAssets"
    domain_name              = module.interop_landing_bucket.s3_bucket_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.landing_s3.id
  }

  origin {
    origin_id                = "JwtWellKnownBucket"
    domain_name              = module.jwt_well_known_bucket.s3_bucket_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.landing_s3.id
  }

  origin {
    origin_id                = "PublicDashboards"
    domain_name              = module.public_dashboards_bucket.s3_bucket_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.landing_s3.id
  }

  origin {
    origin_id                = "PublicCatalog"
    domain_name              = module.public_catalog_bucket.s3_bucket_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.landing_s3.id

    origin_path = "/catalog"
  }

  default_cache_behavior {
    target_origin_id       = "S3FrontendAssets"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cached_methods  = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress        = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_react_app.arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/.well-known/*"
    target_origin_id       = "JwtWellKnownBucket"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cached_methods  = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress        = true
  }

  ordered_cache_behavior {
    path_pattern           = "/kpis-dashboard.json"
    target_origin_id       = "PublicDashboards"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cached_methods  = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
    compress        = true

    origin_request_policy_id = (var.env == "test" ?
    data.aws_cloudfront_origin_request_policy.cors_s3_origin.id : null)
  }

  ordered_cache_behavior {
    path_pattern           = "/eservice_a_catalogo.json"
    target_origin_id       = "PublicCatalog"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cached_methods  = ["GET", "HEAD"]
    cache_policy_id = aws_cloudfront_cache_policy.public_catalog.id
    compress        = true
  }

  ordered_cache_behavior {
    path_pattern           = "/metrics.json"
    target_origin_id       = "PublicDashboards"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cached_methods  = ["GET", "HEAD"]
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
    compress        = true

    origin_request_policy_id = (var.env == "test" ?
    data.aws_cloudfront_origin_request_policy.cors_s3_origin.id : null)
  }
}
