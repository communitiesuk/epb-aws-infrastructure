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
    timeout             = "30"
    path                = "/"
    unhealthy_threshold = "3"
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
  certificate_arn = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }

  depends_on = [aws_lb_target_group.public]

}

resource "aws_alb_listener_rule" "this" {
  listener_arn = aws_lb_listener.public_https.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.public.arn

  }
  condition {
     path_pattern {
        values = ["/*"]
     }

  }
}



