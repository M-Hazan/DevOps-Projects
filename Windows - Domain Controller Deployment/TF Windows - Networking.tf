resource "aws_vpc" "Spudinaws-VPC" {
  cidr_block           = "10.64.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "Spudinaws-VPC"
  }
}

resource "aws_internet_gateway" "Spudinaws-IGW" {
  vpc_id = aws_vpc.Spudinaws-VPC.id

  tags = {
    Name = "Spudinaws-IGW"
  }
}

resource "aws_route_table" "Spudinaws-Public-RT" {
  vpc_id = aws_vpc.Spudinaws-VPC.id

  tags = {
    Name = "Spudinaws-Public-RT"
  }
}

resource "aws_subnet" "Spudinaws-Public-Subnet_us-east-1a" {
  vpc_id                  = aws_vpc.Spudinaws-VPC.id
  cidr_block              = "10.64.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Spudinaws-Pub-Subnet-10-64-10"
  }
}

resource "aws_subnet" "Spudinaws-Public-Subnet_us-east-1b" {
  vpc_id                  = aws_vpc.Spudinaws-VPC.id
  cidr_block              = "10.64.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Spudinaws-Pub-Subnet-10-64-11"
  }
}

resource "aws_route" "Spudinaws-Public-RT-Routes" {
  route_table_id         = aws_route_table.Spudinaws-Public-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Spudinaws-IGW.id
}

resource "aws_route_table_association" "Associate-Spudinaws-Public-Subnet_us-east-1a----Spudinaws-Public-RT-Routes" {
  subnet_id      = aws_subnet.Spudinaws-Public-Subnet_us-east-1a.id
  route_table_id = aws_route_table.Spudinaws-Public-RT.id
}