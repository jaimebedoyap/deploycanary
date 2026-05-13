# Definimos el proveedor
provider "aws" {
  region = "us-east-1"
}

# 1. Creamos la VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devops-learning-vpc"
  }
}

# 2. Creamos una Subred Pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-sn"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# 4. Route Table pública (AÑADIDO - faltaba para que el IGW funcione)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# 5. Asociación de la Route Table con la subred pública (AÑADIDO)
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Grupo de Seguridad (duplicado eliminado)
resource "aws_security_group" "web_sg" {
  name        = "allow_web_traffic"
  description = "Permitir trafico SSH y HTTP"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description = "SSH desde mi IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Reemplaza con tu IP: ["X.X.X.X/32"]
  }

  ingress {
    description = "HTTP desde cualquier lugar"
    from_port   = 80
    to_port     = 80
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
    Name = "web-traffic-sg"
  }
}

# 7. AMI más reciente de Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 8. Instancia EC2
resource "aws_instance" "devops_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro" # t3.micro reemplaza al deprecado t2.micro
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo chkconfig docker on
    docker run -d -p 80:80 --name web-server nginx
  EOF

  tags = {
    Name = "jaime-devops-node"
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "jaime-key"
  public_key = file("my-devops-key.pub")
}

# Luego, busca el recurso aws_instance y añade esta línea dentro:
# key_name = aws_key_pair.deployer.key_name