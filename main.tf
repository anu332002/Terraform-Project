provider "aws" {}

variable "Environment" {
  description = "deployment Environment"
}

variable "cidr_block" {
  description = "cidr_block for vpc and subnets"
  type = list(object(
    {
      cidr_block=string,
      Name=string
    }
  ))
}

resource "aws_vpc" "development-vpc" {
    cidr_block = var.cidr_block[0].cidr_block
    tags = {
      Name=var.cidr_block[0].Name
      vpc_env=var.Environment
    }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.cidr_block[1].cidr_block
  availability_zone = "eu-west-3a"
  tags = {
    Name=var.cidr_block[1].Name
  }
}

data "aws_vpc" "existing_vpc" {
    cidr_block = aws_vpc.development-vpc.cidr_block
  
}

variable "avai_zone" {}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block = var.cidr_block[2].cidr_block
  availability_zone = var.avai_zone
  tags = {
    Name=var.cidr_block[2].Name
  }
}

output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id 
}

output "dev-subnet-id" {
  value = aws_subnet.dev-subnet-1.id
}