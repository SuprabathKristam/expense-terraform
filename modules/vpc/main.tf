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

resource "aws_vpc_peering_connection" "main" {
  vpc_id      = aws_vpc.main.id         #in the first line we gave name as main for this VPC
  peer_vpc_id = data.aws_vpc.default.id # we are calling from data.tf
  auto_accept = true    # we are accepting the connection

  tags = {
    Name      = "${var.env}-vpv-with-default-vpc"
  }
}
