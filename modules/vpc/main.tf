resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-${var.project_name}-vpc"
  }
}

resource "aws_subnet" "main" {
  count             = length(var.subnets_cidr)  #we provided 2 values in the subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.subnets_cidr,count.index)  # we are calling each value in subnets-cidr
  availability_zone = element(var.az,count.index)

  tags = {
    Name = "subnet-${count.index}"
  }
}