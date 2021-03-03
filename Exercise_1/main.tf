# Designate a cloud provider, region, and credentials
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

# provision 4 AWS t2.micro EC2 instances named Udacity T2
resource "aws_instance" "Udacity_T2" {
  count = 4
  subnet_id = var.subnet_id
  ami = "ami-066c82dabe6dd7f73"
  instance_type = "t2.micro"
  tags = {
    Name = "Server ${count.index}"
  }
}

# provision 2 m4.large EC2 instances named Udacity M4
resource "aws_instance" "Udacity_M4" {
  count = 2
  subnet_id = var.subnet_id
  ami = "ami-066c82dabe6dd7f73"
  instance_type = "m4.large"
  tags = {
    Name = "M4 Server ${count.index}"
  }
}