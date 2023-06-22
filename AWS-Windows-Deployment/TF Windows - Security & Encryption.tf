

resource "tls_private_key" "DC-Private-Key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "DC-Public-Key" {
  key_name   = "DC-Key"
  public_key = tls_private_key.DC-Private-Key.public_key_openssh
}

resource "local_file" "Local-Private-Key-File" {
  content         = tls_private_key.DC-Private-Key.private_key_pem
  filename        = "DC-Private-Key.pem"
  file_permission = "0600"
}