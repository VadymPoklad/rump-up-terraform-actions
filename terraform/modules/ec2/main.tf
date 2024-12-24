provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "ssh_private_key" {
  name        = "pet-clinic-ssh-private-key"
  description = "Private SSH key for EC2 access"
}

resource "aws_secretsmanager_secret_version" "ssh_private_key_version" {
  secret_id     = aws_secretsmanager_secret.ssh_private_key.id
  secret_string = tls_private_key.example.private_key_pem
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "my-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow traffic for EC2 instances"
  vpc_id      = var.vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  }
}

resource "aws_instance" "web_server" {
  count                      = length(var.subnet_ids)
  ami                        = var.ami_id
  instance_type              = var.instance_type
  subnet_id                  = element(var.subnet_ids, count.index)
  associate_public_ip_address = true
  key_name                   = aws_key_pair.ec2_key_pair.key_name
  iam_instance_profile       = aws_iam_instance_profile.ec2_role_profile.name
  vpc_security_group_ids     = [aws_security_group.ec2_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              sudo apt install -y openssh-server openssl
              ssh -V
              openssl version
              sudo apt install -y openssh-server openssl
              sudo systemctl restart ssh
            EOF

  tags = {
    Name = "web-server-${count.index + 1}"
    Role = "WebServer"
  }
}


resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_lb" "application_load_balancer" {
  name                        = "app-lb"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.ec2_sg.id]
  subnets                     = var.subnet_ids
  enable_deletion_protection  = false
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "target_group" {
  name     = "ec2-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    port                = "traffic-port"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "OK"
    }
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count               = length(var.subnet_ids)
  target_group_arn    = aws_lb_target_group.target_group.arn
  target_id           = aws_instance.web_server[count.index].id
  port                = 8080
}
