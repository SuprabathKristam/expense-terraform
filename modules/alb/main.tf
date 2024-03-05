resource "aws_security_group" "main" {  # This is the security group for load balancer
  name        = "${local.name}-alb-security-group"
  description = "${local.name}-alb-security-group"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80  #Security group will allow port 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
    description      = "HTTP"
  }

  ingress {
    from_port        = 443 #Security group will allow port 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
    description      = "HTTPS"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${local.name}-security-group"
  }
}

resource "aws_lb" "main" {
  name               = local.name
  internal           = var.internal
  load_balancer_type = "application" #this is application load balancer
  security_groups    = [aws_security_group.main.id]
  subnets            = var.subnets

  tags = {
    Name             = local.name
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}
