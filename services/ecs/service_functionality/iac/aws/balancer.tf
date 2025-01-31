
# Create a load balancer for the ECS service
resource "aws_lb" "lb" {
  name               = "${local.base_name_with_hyphen}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = data.aws_subnets.default.ids
  idle_timeout       = 4000
  enable_deletion_protection = false
}

# Create a target group for the ECS service
resource "aws_lb_target_group" "tg" {
  name     = "${local.base_name_with_hyphen}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 60
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Create a listener for the load balancer
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  lifecycle {
    prevent_destroy = false
  }
}
