resource "aws_lb" "public" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.logs_bucket_name
    prefix  = "${var.prefix}-alb"
    enabled = true
  }

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "public" {
  name        = "${var.prefix}-alb-tg"
  port        = var.container_port
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

  ssl_policy = "ELBSecurityPolicy-2016-08"
  # When trying to associate certificate with the listener, you may see terraform errors if the certificate hasn't been validated yet
  # See "Setting up SSL Certificates" in README for more info
  certificate_arn = var.aws_ssl_certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.public.id
    type             = "forward"
  }
}