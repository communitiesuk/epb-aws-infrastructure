resource "aws_lb" "public" {
  name                       = "${var.prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public_subnet[*].id
  drop_invalid_header_fields = true
  enable_deletion_protection = false

}

resource "aws_lb_target_group" "public" {
  # See https://github.com/hashicorp/terraform-provider-aws/issues/636#issuecomment-637761075
  # The name_prefix, lifecycle and tags are so the resource could be replaced
  # when changing the port
  name_prefix = "epbptg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    interval            = 20
    protocol            = "HTTP"
    matcher             = "200,302"
    timeout             = 5
    path                = "/healthcheck"
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.prefix}-alb-tg"
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
}

resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn

  }
  condition {
    path_pattern {
      values = ["/*"]
    }

  }
}
