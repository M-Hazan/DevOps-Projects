terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

############ NETWORKING SECTION ############

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

resource "aws_route" "Spudinaws-Public-RT-Routes" {
  route_table_id         = aws_route_table.Spudinaws-Public-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Spudinaws-IGW.id
}

resource "aws_route_table_association" "Associate-Spudinaws-Public-Subnet_us-east-1a----Spudinaws-Public-RT-Routes" {
  subnet_id      = aws_subnet.Spudinaws-Public-Subnet_us-east-1a.id
  route_table_id = aws_route_table.Spudinaws-Public-RT.id
}

############ IAM SECTION ############

resource "aws_security_group" "Spudinaws-SG" {
  vpc_id      = aws_vpc.Spudinaws-VPC.id
  name        = "Spudinaws-SG"
  description = "Security Group by Terraform"

  tags = {
    Name = "Spudinaws-SG"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############ SECURITY AND SSH KEYS SECTION ############

resource "tls_private_key" "Spudinaws-PrivateKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "Spudinaws-PublicKey" {
  key_name   = "Spudinaws-SSHKey"
  public_key = tls_private_key.Spudinaws-PrivateKey.public_key_openssh
}

resource "local_file" "Local-Private-Key-File" {
  content         = tls_private_key.Spudinaws-PrivateKey.private_key_pem
  filename        = "Spudinaws-PrivateKey.pem"
  file_permission = "0600"
}

############ COMPUTE SECTION ############

resource "aws_instance" "Terraform-ansible-web" {
  ami                    = "ami-0715c1897453cabd1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Spudinaws-SG.id]
  subnet_id              = aws_subnet.Spudinaws-Public-Subnet_us-east-1a.id
  key_name               = aws_key_pair.Spudinaws-PublicKey.key_name

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "Terraform-ansible-web"
  }
}

############ OUTPUT SECTION ############

output "Public_IP" {
  value = aws_instance.Terraform-ansible-web.public_ip
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = templatefile("${path.module}/inventory.tpl", { ip = aws_instance.Terraform-ansible-web.public_ip })
}
