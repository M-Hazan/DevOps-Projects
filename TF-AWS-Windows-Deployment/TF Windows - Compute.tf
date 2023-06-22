

resource "aws_instance" "TerraformEC2-DC" {
  ami                    = "ami-04132f301c3e4f138"
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.Terraform_DC-SG.id]
  subnet_id              = aws_subnet.Spudinaws-Public-Subnet_us-east-1a.id
  key_name               = aws_key_pair.DC-Public-Key.key_name

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "TerraformEC2-DC"
  }



}

