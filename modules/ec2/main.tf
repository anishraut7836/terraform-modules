resource "aws_instance" "first_ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  tags = {
    Name = var.instance-name
}
}