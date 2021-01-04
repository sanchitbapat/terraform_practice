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

# 1. Create a VPC
resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "tf_vpc"
  }
}

# 2. Create Internet gateway

resource "aws_internet_gateway" "tf_gw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf_gw"
  }
}

# 3. Create a custom Route Table

resource "aws_route_table" "tf_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.tf_gw.id
  }

  tags = {
    Name = "tf_route_table"
  }
}

# 4. Create a Subnet

resource "aws_subnet" "tf_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "tf_subnet"
  }
}

# 5. Associate seubnet with Route Table

resource "aws_route_table_association" "tf_rt_association" {
  subnet_id      = aws_subnet.tf_subnet.id
  route_table_id = aws_route_table.tf_route_table.id
}

# 6. Create Security Goup to allow ports 22, 80, 443

resource "aws_security_group" "tf_sg" {
  name        = "tf_sg"
  description = "Allow HTTP, HTTPS and SSH traffic"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "tf_sg"
  }
}

# 7 Create a Network Interface

resource "aws_network_interface" "tf_nic" {
  subnet_id       = aws_subnet.tf_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.tf_sg.id]

  tags = {
    Name = "tf_nic"
  }
}

# 8 Create Elastic IP

resource "aws_eip" "tf_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.tf_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.tf_gw]
  tags = {
    Name = "tf_eip"
  }
}

# 9. Create EC2 Instance

resource "aws_instance" "tf_ec2" {
  ami               = "ami-0663c8300ef945e88"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  key_name          = var.keyname

  network_interface {
    device_index        = 0
    network_interface_id = aws_network_interface.tf_nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo hello world > /var/www/html/index.html'
              EOF

  tags= {
    Name = "tf_ec2"
  }

}

