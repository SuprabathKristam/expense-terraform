resource "aws_db_parameter_group" "main" {
  name   = "rds-pg"
  family = "mysql5.6"
}

resource "aws_db_instance" "main" {
  allocated_storage    = var.allocated_storage
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.username      # we will define username and password in parameter store
  password             = var.password
  parameter_group_name = aws_db_parameter_group.main.name# For any configuration related to BD we use this which we are creating above
  skip_final_snapshot  = true # asking permission to delete DB when we use destroy(in companies it will be true)
}
