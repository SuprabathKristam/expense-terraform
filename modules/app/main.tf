resource "aws_security_group" "main" {
  name        = "${local.name}-security-group"
  description = "${local.name}-rds-security-group"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 22     # port of ssh
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidrs #Our work station is bastion node here
    description      = "SSH"
  }

  ingress {                             #for application
    from_port        = var.app_port     # port of app
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
    description      = "APPPORT"
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

resource "aws_launch_template" "main" {
  name_prefix   = "${local.name}-launch-template"
  image_id      = data.aws_ami.centos-8.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    service_name = var.component
    env          = var.env
  }))

  iam_instance_profile {
    name = aws_iam_role.main.name
  }
}

resource "aws_autoscaling_group" "main" {
  name               = "${local.name}-autoscaling-group"
  desired_capacity   = var.instance_capacity # number of instances needed
  max_size           = var.instance_capacity+10 #This we will fine tune after autoscaling
  min_size           = var.instance_capacity #max number of instances needed
  vpc_zone_identifier = var.vpc_zone_identifier
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id #we are calling above created launch template here
    version = "$Latest"
  }
  tag {
    key                  = "Name"   #For every instance that is launched the below name we given
    value                = local.name
    propagate_at_launch  = true

  }
}

resource "aws_lb_target_group" "main" {
  name     = "${local.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/health"
    healthy_threshold = 2 #this will check healthy twice
    unhealthy_threshold = 2 #this will check unhealthy twice
    interval = 5 # this will check the target every 5 seconds health is good or bad
    timeout = 2 #timeout to do health check
  }
}

resource "aws_iam_role" "main" {
  name               = "${local.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = "parameter-store"

    policy = jsonencode({     # we have taken code from manually created Test poly from console
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "GetParameters", # we gave this in generic way
          "Effect": "Allow",
          "Action": [
            "ssm:GetParameterHistory",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          "Resource":conact([
            "arn:aws:ssm:us-east-1:872150321686:parameter/${var.env}.${var.project_name}.${var.component}.*"
          ],var.parameters)
        },
        {
          "Sid": "DescribeAllParameters", #we have this in generic way
          "Effect": "Allow",
          "Action": "ssm:DescribeParameters",
          "Resource": "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.name}-role"
  role = aws_iam_role.main.name
}
