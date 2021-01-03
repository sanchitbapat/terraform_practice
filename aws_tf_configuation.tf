terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

# Create a VPC
resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "tf_vpc"
  }
}

resource "aws_subnet" "tf_subnet-1" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "tf_subnet-1"
  }
}



#resource "aws_instance" "example" {
#  ami             = "ami-0663c8300ef945e88"
#  instance_type   = "t2.micro"
#  key_name        = var.keyn
#  security_groups = ["ansible test group"]
#}
#
#output "ip" {
#  value = aws_instance.example.public_ip
#}
