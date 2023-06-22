
resource "aws_security_group" "Terraform_DC-SG" {
  vpc_id      = aws_vpc.Spudinaws-VPC.id
  name        = "Terraform_DC-SG"
  description = "Domain Controllers Security Group by Terraform"

  tags = {
    Name = "Terraform_DC-SG"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
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