locals {
  waf_bff_prefix_regex = (local.deploy_new_bff_apigw
    ? "^/\\d\\.\\d/backend-for-frontend"
    : "^/backend-for-frontend/.*"
  )
}

resource "aws_wafv2_web_acl" "interop" {
  name  = format("%s-web-acl-%s", var.short_name, var.env)
  scope = "REGIONAL"

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MetricForWebACLWithAMR"
    sampled_requests_enabled   = false
  }

  default_action {
    allow {}
  }

  rule {
    name     = "Default-AWSManagedRulesCommonRuleSet"
    priority = 0

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForAMRCRS"
      sampled_requests_enabled   = false
    }

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "NoUserAgent_HEADER"
          action_to_use {
            count {}
          }
        }

        scope_down_statement {
          and_statement {
            statement {
              not_statement {
                statement {
                  regex_match_statement {
                    field_to_match {
                      uri_path {}
                    }
                    regex_string = "${local.waf_bff_prefix_regex}/eservices/.*/descriptors/.*/documents$"
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }

            statement {
              not_statement {
                statement {
                  regex_match_statement {
                    field_to_match {
                      uri_path {}
                    }
                    regex_string = "${local.waf_bff_prefix_regex}/agreements/.*/consumer-documents$"
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }

            statement {
              not_statement {
                statement {
                  regex_match_statement {
                    field_to_match {
                      uri_path {}
                    }
                    regex_string = "${local.waf_bff_prefix_regex}/eservices/templates/.*/documents$"
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  rule {
    name     = "FileUpload-AWSManagedRulesCommonRuleSet"
    priority = 1

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForAMRCRS"
      sampled_requests_enabled   = false
    }

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "NoUserAgent_HEADER"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "CrossSiteScripting_BODY"
          action_to_use {
            count {}
          }
        }

        scope_down_statement {
          or_statement {
            statement {
              regex_match_statement {
                field_to_match {
                  uri_path {}
                }
                regex_string = "${local.waf_bff_prefix_regex}/eservices/.*/descriptors/.*/documents$"
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            statement {
              regex_match_statement {
                field_to_match {
                  uri_path {}
                }
                regex_string = "${local.waf_bff_prefix_regex}/agreements/.*/consumer-documents$"
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            statement {
              regex_match_statement {
                field_to_match {
                  uri_path {}
                }
                regex_string = "${local.waf_bff_prefix_regex}/eservices/templates/.*/documents$"
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  name = format("aws-waf-logs-%s", var.env)

  retention_in_days = var.env == "prod" ? 90 : 30
  skip_destroy      = true
}

resource "aws_wafv2_web_acl_logging_configuration" "interop" {
  resource_arn            = aws_wafv2_web_acl.interop.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
