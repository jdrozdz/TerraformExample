resource "tls_private_key" "ssh-key-gen" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

locals {
  public_ssh_key = tls_private_key.ssh-key-gen.public_key_openssh
}