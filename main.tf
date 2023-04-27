provider "aws" {
  region  = "us-east-1"
  profile = "aws_academy"
}

resource "aws_vpc" "my_app_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "my_app_igw" {
  vpc_id = aws_vpc.my_app_vpc.id
}

resource "aws_subnet" "public_e" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.my_app_vpc.id
  availability_zone       = "us-east-1e"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_f" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.my_app_vpc.id
  availability_zone       = "us-east-1f"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_app_igw.id
  }
}

resource "aws_route_table_association" "public_e" {
  subnet_id      = aws_subnet.public_e.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_f" {
  subnet_id      = aws_subnet.public_f.id
  route_table_id = aws_route_table.public.id
}


resource "aws_key_pair" "instance_keypair" {
  key_name   = "instance_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "eip_instance_e" {
  vpc = true
}

resource "aws_eip" "eip_instance_f" {
  vpc = true
}

resource "aws_security_group" "my_app_sg" {
  name        = "my_app_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.my_app_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

}

resource "aws_instance" "instance_e" {
  ami       = "ami-03c7d01cf4dedc891"
  subnet_id = aws_subnet.public_e.id
  key_name  = aws_key_pair.instance_keypair.key_name
  user_data = file("user-data.sh")

  instance_type = "t2.micro"

  security_groups = [aws_security_group.my_app_sg.id]

  tags = {
    Name = "My App - Instance 1"
  }
}

resource "aws_instance" "instance_f" {
  ami       = "ami-03c7d01cf4dedc891"
  subnet_id = aws_subnet.public_f.id
  key_name  = aws_key_pair.instance_keypair.key_name
  user_data = file("user-data.sh")

  instance_type = "t2.micro"

  security_groups = [aws_security_group.my_app_sg.id]

  tags = {
    Name = "My App - Instance 2"
  }
}

resource "aws_eip_association" "eip_assoc_instance_e" {
  instance_id   = aws_instance.instance_e.id
  allocation_id = aws_eip.eip_instance_e.id
}

resource "aws_eip_association" "eip_assoc_instance_f" {
  instance_id   = aws_instance.instance_f.id
  allocation_id = aws_eip.eip_instance_f.id
}

resource "aws_alb_target_group" "my_app_gd" {
  name             = "my-app-gd"
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"

  vpc_id = aws_vpc.my_app_vpc.id
}

resource "aws_alb_target_group_attachment" "my_app_tg_attachment_e" {
  target_group_arn = aws_alb_target_group.my_app_gd.arn
  target_id        = aws_instance.instance_e.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "my_app_tg_attachment_f" {
  target_group_arn = aws_alb_target_group.my_app_gd.arn
  target_id        = aws_instance.instance_f.id
  port             = 80
}

resource "aws_alb_listener" "my_app_alb_listener" {
  load_balancer_arn = aws_alb.my_app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.my_app_gd.arn
    type             = "forward"
  }
}

resource "aws_alb" "my_app_alb" {
  name               = "MyAppBalanceador"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_app_sg.id]
  subnets            = [aws_subnet.public_e.id, aws_subnet.public_f.id]
}


