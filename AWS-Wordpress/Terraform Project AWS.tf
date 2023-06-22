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

resource "aws_security_group" "Terraform_WP-SG" {
  vpc_id      = aws_vpc.Spudinaws-VPC.id
  name        = "Terraform_WP-SG"
  description = "Wordpress Security Group by Terraform"

  tags = {
    Name = "Terraform_WP-SG"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "TerraformEC2-WP" {
  ami                    = "ami-0715c1897453cabd1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Terraform_WP-SG.id]
  subnet_id              = aws_subnet.Spudinaws-Public-Subnet_us-east-1a.id

  user_data = <<-EOF
#!/bin/bash -xe
    DBName='SpudinawsDB'
    DBUser='Spudinaws'
    DBPassword='HelloLetsGo'
    DBRootPassword='HelloLetsGo'
    sudo dnf -y update
    sudo dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel stress -y
    sudo systemctl enable httpd
    sudo systemctl enable mariadb
    sudo systemctl start httpd
    sudo systemctl start mariadb
    sudo mysqladmin -u root password $DBRootPassword
    sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html
    cd /var/www/html
    sudo tar -zxvf latest.tar.gz
    sudo cp -rvf wordpress/* .
    sudo rm -R wordpress
    sudo rm latest.tar.gz
    sudo cp ./wp-config-sample.php ./wp-config.php
    sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
    sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
    sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
    sudo usermod -a -G apache ec2-user   
    sudo chown -R ec2-user:apache /var/www
    sudo chmod 2775 /var/www
    sudo find /var/www -type d -exec chmod 2775 {} \;
    sudo find /var/www -type f -exec chmod 0664 {} \;
    sudo echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
    sudo echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
    sudo echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
    sudo echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
    sudo mysql -u root --password=$DBRootPassword < /tmp/db.setup
    sudo rm /tmp/db.setup
    EOF

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "TerraformEC2-WP"
  }
}

output "Wordpress_Website_IP" {
  value = aws_instance.TerraformEC2-WP.public_ip
}