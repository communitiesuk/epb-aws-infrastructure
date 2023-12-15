locals {
  create_internal_alb = var.internal_alb_config != null
}

resource "aws_lb" "internal" {
  count = local.create_internal_alb ? 1 : 0

  name                             = "${var.prefix}-in-alb"
  internal                         = true
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb_internal[0].id]
  subnets                          = var.private_subnet_ids
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields       = true

  access_logs {
    bucket  = var.logs_bucket_name
    prefix  = "${var.prefix}-in-alb"
    enabled = true
  }

  enable_deletion_protection = false

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_lb_target_group" "internal" {
  count = local.create_internal_alb ? 1 : 0

  name                 = "${var.prefix}-in-alb-tg"
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 80
  slow_start           = 60

  health_check {
    interval            = "31"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "30"
    path                = var.health_check_path
    unhealthy_threshold = "10"
    healthy_threshold   = "2"
  }
}

resource "aws_lb_listener" "public_http" {
  count = local.create_internal_alb ? 1 : 0

  load_balancer_arn = aws_lb.internal[0].id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    replace_triggered_by = [aws_lb_target_group.internal[0].id]
  }
}

resource "aws_lb_listener" "public_https" {
  count = local.create_internal_alb ? 1 : 0

  load_balancer_arn = aws_lb.internal[0].id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # When trying to associate certificate with the listener, you may see terraform errors if the certificate hasn't been validated yet
  # See "Setting up SSL Certificates" in README for more info
  certificate_arn = var.internal_alb_config.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal[0].id
  }
}
