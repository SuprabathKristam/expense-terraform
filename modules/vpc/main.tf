resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-${var.project_name}-vpc"
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

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id    # Attaching the new VPC we created

  tags = {
    Name = "${var.env}-${var.project_name}-igw"  #igw stands for internet gateway
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnets_cidr, count.index)
  availability_zone = element(var.az, count.index)

  tags = {
    Name = "public-subnet-${count.index+1}"
  }
}

resource "aws_route_table" "public" {
  count = length(var.public_subnets_cidr)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # Here we are attaching internet Gateway
  }
  route {
    cidr_block                = data.aws_vpc.default.cidr_block   # creating  a peering connection
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }
  tags = {
    Name = "public-rt-${count.index+1}"
  }
}

resource "aws_route_table_association" "public" {  #Used for mapping of newly created route tables
  count          = length(var.public_subnets_cidr)
  route_table_id = lookup(element(aws_route_table.public, count.index),"id", null) #aws_route_table.public[count.index].id
  subnet_id      = lookup(element(aws_subnet.public, count.index),"id", null )
}

resource "aws_eip" "main" {  # Creating 2 elastic ip's
  count  = length(var.public_subnets_cidr)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets_cidr)
  allocation_id = lookup(element(aws_eip.main, count.index), "id", null)
  subnet_id     = lookup(element(aws_subnet.public, count.index), "id", null)

  tags = {
    Name = "ngw-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets_cidr, count.index)
  availability_zone = element(var.az, count.index)

  tags = {
    Name = "private-subnet-${count.index+1}"
  }
}
resource "aws_route_table" "private" {
  count = length(var.private_subnets_cidr)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = lookup(element(aws_nat_gateway.main, count.index), "id", null)  # Here we are attaching to NAT Gateway
  }
  route {
    cidr_block                = data.aws_vpc.default.cidr_block   # creating  a peering connection
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }
  tags = {
    Name = "private-rt-${count.index+1}"
  }
}

resource "aws_route_table_association" "private" {  #Used for mapping of newly created route tables
  count          = length(var.private_subnets_cidr)
  route_table_id = lookup(element(aws_route_table.private, count.index),"id", null) #aws_route_table.private[count.index].id
  subnet_id      = lookup(element(aws_subnet.private, count.index),"id", null )
}



resource "aws_route" "main" {     #main means the new vpc
  route_table_id            = aws_vpc.main.main_route_table_id
  destination_cidr_block    = data.aws_vpc.default.cidr_block  # this is default vpc cidr block which is destination and getting from data.tf
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id #From above created peering connection
}

resource "aws_route" "default_vpc" {
  route_table_id            = data.aws_vpc.default.main_route_table_id #This is default vpc table id
  destination_cidr_block    = aws_vpc.main.cidr_block # This is the new vpc cidr block which is a destination in this case
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id #From above created peering connection
}
#This is just for example we will remove it later

data "aws_ami" "example" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = ["973714476881"]
}

resource "aws_security_group" "test" {
  name = "test"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {                          # Here ingress and egress we are writing to allow ports in and out
    from_port        = 0
    to_port          = 0
    protocol         = "-1"   # All ports
    cidr_blocks      = ["0.0.0.0/0"]   #All traffic
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_instance" "test" {
  ami           = data.aws_ami.example.image_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private[0].id #lookup(element(aws_subnet.main,0),"id",null) this also can be used
  vpc_security_group_ids = [aws_security_group.test.id]  # Calling the above created security groups here
}

