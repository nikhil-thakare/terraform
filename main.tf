terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.27.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "jenkins_master" {
  ami             = "ami-02f3416038bdb17fb"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.jenkins-key.key_name
  security_groups = [aws_security_group.jenkins-sg.name]
  user_data       = local.user_data


  tags = {
    Name = "jenkins_master"
  }
}
resource "aws_instance" "jenkins_node" {
  ami             = "ami-02f3416038bdb17fb"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.jenkins-key.key_name
  security_groups = [aws_security_group.jenkins-sg.name]
  user_data       = local.user_data_node



  tags = {
    Name = "jenkins_node"
  }
}
resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-sg"
  description = "jenkins-sg"
  

  ingress {
    description      = "jenkins"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
resource "aws_key_pair" "jenkins-key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "jenkins-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "tf-key"
}
