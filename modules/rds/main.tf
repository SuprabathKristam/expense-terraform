resource "aws_db_parameter_group" "main" {
  name   = "${var.env}-${var.project_name}-pg"
  family = var.family
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-${var.project_name}-sg"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "${var.env}-${var.project_name}-sg"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.env}-${var.project_name}-rds-security-group"
  description = "${var.env}-${var.project_name}-rds-security-group"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 3306     # port of sql
    to_port          = 3306
    protocol         = tcp
    cidr_blocks      = var.sg_cidr_blocks
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env}-${var.project_name}-rds-security-group"
  }
}

resource "aws_db_instance" "main" {
  identifier           = "${var.env}-${var.project_name}-rds" #This is the name we are giving to DB instance 
  allocated_storage    = var.allocated_storage
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = data.aws_ssm_parameter.username.value
  password             = data.aws_ssm_parameter.password.value
  parameter_group_name = aws_db_parameter_group.main.name# For any configuration related to BD we use this which we are creating above
  skip_final_snapshot  = true # asking permission to delete DB when we use destroy(in companies it will be true)
  storage_encrypted    = true # As this is a DB we should encrypt for sure
  kms_key_id           = var.kms_key_id
  db_subnet_group_name = aws_db_subnet_group.main.name # we are telling to create DB isnatnces in this subnet group
  vpc_security_group_ids = [aws_security_group.main.id] #here we are telling to use these security group id's for the DB instance
}

