//----------lesson27--Modules--main----
//----Resources--------------------

/*
provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    bucket = "lion-terraform-state"
    key    = "dev/network/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
*/
//--------------------------------------------------------

data "aws_availability_zones" "avalable" {} # request AZ data

//---------create vpc------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env} My_VPC"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-my_igw_les27"
  }
}

//============create public subnets=============

resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidrs) # count = numver cidr blockes in var public_subnet_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index) # count.index = take one by one
  availability_zone       = data.aws_availability_zones.avalable.names[count.index]
  map_public_ip_on_launch = true # attach public IP for servers
  tags = {
    Name = "${var.env} public${count.index + 1}"
  }
}
//-------------create route_table--------------------------
resource "aws_route_table" "public_subnet" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" #  all external traffic flows to gateway_id (aig)
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env} routing_public"
  }
}
// Attach route table to subnets

resource "aws_route_table_association" "public_subnet" {
  count          = length(aws_subnet.public_subnet[*].id) # count = Number of subnets
  route_table_id = aws_route_table.public_subnet.id
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index) # count.index = take one by one
}

//-------------------EIP for NAT gw (Private subtens)----------------------------

resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
  tags = {
    Name = "${var.env}-NATgw-${count.index + 1}"
  }
}
//-----------------------NAT GW-------------------
resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public_subnet[*].id, count.index)
  tags = {
    Name = "${var.env}-NATgw-${count.index + 1}"
  }
}
//=================Private subtes=============================
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidrs) # count = numver cidr blockes in var public_subnet_cidrs
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index) # count.index = take one by one
  availability_zone = data.aws_availability_zones.avalable.names[count.index]
  tags = {
    Name = "${var.env}-private-${count.index + 1}"
  }
}
//----------private route table-----------------------
resource "aws_route_table" "private_subnet" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" #  all external traffic flows to gateway_id (NAT)
    gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "${var.env}-routing_private_table-${count.index + 1}"
  }
}
// Attach route table to subnets

resource "aws_route_table_association" "private_subnet" {
  count          = length(aws_subnet.private_subnet[*].id) # count = Number of subents
  route_table_id = aws_route_table.private_subnet[count.index].id
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index) # count.index = take one by one
}
