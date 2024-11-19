provider "aws" {
  region     = "eu-west-3"
  access_key = "AKIA2OAJTXXDH23V2R7I"
  secret_key = "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"
}

variable "Environment" {
  description = "deployment Environment"
}
variable "env-prefix" {}
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avai_zone" {}
variable "my_ip" {}
variable "instance_type" {}
variable "ssh_key_location" {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
      Name="${var.env-prefix}-vpc"
      vpc_env=var.Environment
    }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avai_zone
  tags = {
    Name="${var.env-prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name="${var.env-prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name="${var.env-prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress{
    from_port = 22   #can be from range 0-1000 or anything but we want only 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress{
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []             #allowing access to vpc endpoints
  }

  tags = {
    Name="${var.env-prefix}-sg-default"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
}

output "aws_ami" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id  #image which the server is based on(OS Image)
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = ["aws_default_security_group.default-sg"]
  availability_zone = var.avai_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

/*(attribute)entry point script that gets executed 
on ec2 instance whenever the server is instantiated. 
Multi-line script. Defined using EOF block. Start with shebang
EOF block will only get executed once.
*/

user_data=file("entry-script.sh")

  tags = {
    Name="${var.env-prefix}-server"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "terraform-keypair"
  public_key = file(var.ssh_key_location)
}

