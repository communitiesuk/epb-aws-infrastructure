locals {
  create_internal_alb = var.create_internal_alb
}

resource "aws_lb" "internal" {
  count = local.create_internal_alb ? 1 : 0

  name                             = "${var.prefix}-in-alb"
  internal                         = true
  load_balancer_type               = "application"
  security_groups                  = var.security_group_ids
  subnets                          = var.public_subnet_ids
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.logs_bucket_name
    prefix  = "${var.prefix}-in-alb"
    enabled = true
  }

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "internal" {
  count = local.create_internal_alb ? 1 : 0

  name        = "${var.prefix}-in-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "internal_http" {
  count = local.create_internal_alb ? 1 : 0

  load_balancer_arn = aws_lb.internal[0].id
  port              = 80
  protocol          = "HTTP"

  #  default_action {
  #    type = "redirect"
  #
  #    redirect {
  #      port        = 443
  #      protocol    = "HTTPS"
  #      status_code = "HTTP_301"
  #    }
  #  }

  # TODO replace this action with the one above when enabling the HTTPS load balancer
  default_action {
    target_group_arn = aws_lb_target_group.internal[0].id
    type             = "forward"
  }
}

#resource "aws_lb_listener" "internal_https" {
#  count = local.create_internal_alb ? 1 : 0

#  load_balancer_arn = aws_lb.internal.id
#  port              = 443
#  protocol          = "HTTPS"
#
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
##  TODO will need to add this when certificates can be made available
##  certificate_arn   = var.alb_tls_cert_arn
#
#  default_action {
#    target_group_arn = aws_lb_target_group.internal[0].id
#    type             = "forward"
#  }
#}