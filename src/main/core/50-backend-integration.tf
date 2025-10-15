data "aws_lb" "backend_alb" {
  name = var.backend_integration_alb_name
}

moved {
  from = module.nlb_v2
  to   = module.nlb
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = format("be-integration-nlb-%s", var.env)

  load_balancer_type = "network"
  internal           = true
  vpc_id             = module.vpc.vpc_id
  subnets            = data.aws_subnets.int_lbs.ids

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 443
      protocol           = "TCP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name             = format("be-integration-alb-tg-%s", var.env)
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "alb"
      targets = {
        backend_alb = {
          target_id = data.aws_lb.backend_alb.arn
          port      = 80
        }
      }
      connection_termination = false
      preserve_client_ip     = true
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        matcher             = "200-499"
      }
    }
  ]
}

resource "aws_api_gateway_vpc_link" "integration" {
  name        = format("interop-backend-integration-%s", var.env)
  description = "VPC Link to connect privately API GW Rest to NLB"
  target_arns = [module.nlb.lb_arn]
}
