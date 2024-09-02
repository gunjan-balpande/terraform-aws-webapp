# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet within the VPC
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Create a route table and a route to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a security group to allow HTTP and SSH traffic
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  # Allow HTTP (port 80) traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22) traffic only from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["202.174.93.15/32"]  # Replace with your actual IP address
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# Create an EC2 instance
# Create an EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-0ba84480150a07294"  # Ensure this AMI ID is correct for your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id

  # Use vpc_security_group_ids instead of security_groups
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Pull the startup script from the GitHub repository
  user_data = <<-EOF
    #!/bin/bash
    # Install Git
    yum install -y git

    # Clone the startup script repository
    git clone https://github.com/gunjan-balpande/startup-script.git

    # Execute the startup script
    /tmp/startup-scripts/startup.sh
  EOF

  tags = {
    Name = "WebServerInstance"
  }
}


# Configure S3 backend for storing Terraform state
terraform {
  backend "s3" {
    bucket = "my-bucket-for-terraform-gunjan"
    key    = "terraform/state"
    region = "us-west-2"
    encrypt = true
  }
}
