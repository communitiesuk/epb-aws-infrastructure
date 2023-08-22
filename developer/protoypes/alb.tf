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
  name        = "${var.prefix}-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
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
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"


  # When trying to associate certificate with the listener, you may see terraform errors if the certificate hasn't been validated yet
  # See "Setting up SSL Certificates" in README for more info
  certificate_arn = aws_acm_certificate.cert.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "403: Forbidden"
      status_code  = "403"
    }
  }
}




