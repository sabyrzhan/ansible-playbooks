terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "kz.sabyrzhan.terraform.backend"
    key    = "ansible_playbooks/aws_ec2_ubuntu/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
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

locals {
  ssh_key_root = "/Users/sabyrzhan/.ssh"
  user_public_key = "${local.ssh_key_root}/id_rsa.pub"
  suffix = terraform.workspace
  aws_key_name = "aws_key_${local.suffix}"
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = local.aws_key_name
  security_groups = [aws_security_group.web_sec_group.id]
  subnet_id = aws_subnet.web_subnet.id

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.volume_size
  }

  provisioner "local-exec" {
    command = <<EOL
echo "[all]" > .ec2_hosts_${local.suffix}
echo ${self.public_ip} >> .ec2_hosts_${local.suffix}
EOL
  }
}

resource "aws_internet_gateway" "web_gateway" {
  vpc_id = aws_vpc.web_vpc.id
}

resource "aws_route_table" "web_route_table" {
  vpc_id = aws_vpc.web_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_gateway.id
  }
}

resource "aws_route_table_association" "web_route_table_assoc" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_route_table.id
}

resource "aws_vpc" "web_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "web_subnet" {
  cidr_block = cidrsubnet(aws_vpc.web_vpc.cidr_block, 3, 1)
  vpc_id = aws_vpc.web_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_security_group" "web_sec_group" {
  vpc_id = aws_vpc.web_vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "access_public_key" {
  key_name   = local.aws_key_name
  public_key = file(local.user_public_key)
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable. NOTE: If you are using an aws_eip with your instance, you should refer to the EIP's address directly and not use `public_ip` as this field will change after the EIP is attached"
  value       = try(aws_instance.web.public_ip, "")
}