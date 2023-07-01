
resource "aws_security_group" "Terraform_CoC-SG" {
  vpc_id      = aws_vpc.Spudinaws-VPC.id
  name        = "Terraform_CoC-SG"
  description = "CoC Security Group by Terraform"

  tags = {
    Name = "Terraform_CoC-SG"
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