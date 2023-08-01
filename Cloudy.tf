terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    organization = "M-Hazan"

    workspaces {
      name = "Terraform-Cloud"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

######################### VARIABLES SECTION #########################

variable "AWS_SECRET_ACCESS_KEY" {
  description = "The secret access key for AWS"
  type        = string
  sensitive   = true
}

variable "AWS_ACCESS_KEY_ID" {
  description = "The access key for AWS"
  type        = string
}


######################### NETWORKING SECTION #########################

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

######################### PUBLIC SUBNETS #########################

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

######################### PRIVATE SUBNETS & INSTANCE CONNECT #########################

resource "aws_subnet" "Spudinaws-Private-Subnet_us-east-1a" {
  vpc_id            = aws_vpc.Spudinaws-VPC.id
  cidr_block        = "10.64.230.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Spudinaws-Priv-Subnet-10-64-230"
  }
}

resource "aws_subnet" "Spudinaws-Private-Subnet_us-east-1b" {
  vpc_id            = aws_vpc.Spudinaws-VPC.id
  cidr_block        = "10.64.231.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Spudinaws-Priv-Subnet-10-64-231"
  }
}

resource "aws_ec2_instance_connect_endpoint" "Spudinaws-EICE" {
  subnet_id          = aws_subnet.Spudinaws-Private-Subnet_us-east-1a.id
  security_group_ids = [aws_security_group.developers.id]
  preserve_client_ip = false

  tags = {
    Name = "Spudinaws-EICE"
  }
}

######################### ROUTE ASSOCIATIONS #########################

# PUBLIC SUBNET ROUTE TABLE

resource "aws_route_table" "Spudinaws-Public-RT" {
  vpc_id = aws_vpc.Spudinaws-VPC.id

  tags = {
    Name = "Spudinaws-Public-RT"
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

resource "aws_route_table_association" "Associate-Spudinaws-Public-Subnet_us-east-1b----Spudinaws-Public-RT-Routes" {
  subnet_id      = aws_subnet.Spudinaws-Public-Subnet_us-east-1b.id
  route_table_id = aws_route_table.Spudinaws-Public-RT.id
}

######################### SECURITY GROUPS #########################

resource "aws_security_group" "developers" {
  name        = "developers"
  description = "Allow SSH EC2 for Developers from specific IP"
  vpc_id      = aws_vpc.Spudinaws-VPC.id

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "SSH to anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ICMP to anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "developers"
  }
}

############ COMPUTE SECTION ############


############ SECURITY AND SSH KEYS SECTION ############

resource "tls_private_key" "Spudinaws-PrivateKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "Spudinaws-PublicKey" {
  key_name   = "Spudinaws-SSHKey"
  public_key = tls_private_key.Spudinaws-PrivateKey.public_key_openssh
}

resource "aws_ssm_parameter" "Spudinaws-PrivateKey-Parameter" {
  name  = "/Spudinaws/PrivateKey"
  type  = "SecureString"
  value = tls_private_key.Spudinaws-PrivateKey.private_key_pem
}
