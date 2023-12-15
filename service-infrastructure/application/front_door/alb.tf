resource "aws_lb" "public" {
  name                       = "${var.prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.logs_bucket_name
    prefix  = "${var.prefix}-alb"
    enabled = true
  }

  enable_deletion_protection = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lb_target_group" "public" {
  name                 = "${var.prefix}-alb-tg"
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

resource "aws_lb_target_group" "extra" {
  count = var.extra_lb_target_groups

  name                 = "${var.prefix}-alb-extra-tg-${count.index}"
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
  load_balancer_arn = aws_lb.public.id
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
    replace_triggered_by = [aws_lb_target_group.public.id]
  }
}

resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # When trying to associate certificate with the listener, you may see terraform errors if the certificate hasn't been validated yet
  # See "Setting up SSL Certificates" in README for more info
  certificate_arn = var.ssl_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "403: Forbidden"
      status_code  = "403"
    }
  }
}


resource "aws_lb_listener_rule" "forward_cdn" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.id
  }

  condition {
    http_header {
      http_header_name = local.cdn_header_name
      values           = [random_password.cdn_header.result]
    }
  }
}

resource "aws_lb_listener_rule" "forward_path_based_overrides" {
  for_each = {
    for index, override in var.path_based_routing_overrides :
    index => override
  }

  listener_arn = aws_lb_listener.public_https.arn
  priority     = 99 - each.key

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }

  condition {
    path_pattern {
      values = each.value.path_pattern
    }
  }
}
