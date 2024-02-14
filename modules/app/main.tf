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
}

resource "aws_autoscaling_group" "main" {
  name               = "${local.name}-autoscaling-group"
  desired_capacity   = var.instance_capacity # number of instances needed
  max_size           = var.instance_capacity+10 #This we will fine tune after autoscaling
  min_size           = var.instance_capacity #max number of instances needed
  vpc_zone_identifier = var.vpc_zone_identifier

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