output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "web_subnet_ids" {
  value = aws_subnet.web.*.id
}

output "app_subnet_ids" {
  value = aws_subnet.app.*.id
}

output "db_subnet_ids" {
  value = aws_subnet.db.*.id
}

#Here we are writting the above blocks to to pass these information to RDS module from VPC module