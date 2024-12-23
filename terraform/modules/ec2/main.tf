resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

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

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-ssm-sg"
  description = "Allow traffic for EC2 instances managed by SSM"
  vpc_id      = var.vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  tags = {
    Name = "ec2-ssm-sg"
  }
}

resource "aws_lb" "application_load_balancer" {
  name                        = "app-lb"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.ec2_sg.id]
  subnets                     = var.public_subnet_ids
  enable_deletion_protection  = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "App-Load-Balancer"
  }

  depends_on = [aws_security_group.ec2_sg]
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

  tags = {
    Name = "Target-Group"
  }

  depends_on = [aws_lb.application_load_balancer]
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

  depends_on = [aws_lb_target_group.target_group]
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count               = length(var.private_subnet_ids)
  target_group_arn    = aws_lb_target_group.target_group.arn
  target_id           = aws_instance.ec2_instances[count.index].id
  port                = 8080

  depends_on = [aws_lb_listener.http_listener]
}

resource "aws_instance" "ec2_instances" {
  count                  = length(var.private_subnet_ids)
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(var.private_subnet_ids, count.index)
  associate_public_ip_address = false
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags = {
    Name = "ec2-instance-${count.index + 1}"
    Role = "WebServer"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum install -y aws-cli
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF

  depends_on = [
    aws_security_group.ec2_sg,
    aws_iam_instance_profile.ec2_ssm_profile
  ]
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_s3_bucket" "ansible_petclinic_ssm" {
  bucket = "ansible-petclinic-ssm" 
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "ansible-petclinic-ssm"
    Project     = "PetClinic"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ssm"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  vpc_endpoint_type  = "Interface" 

  tags = {
    Name = "ssm-interface-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  vpc_endpoint_type       = "Interface"  

  tags = {
    Name = "ec2messages-interface-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  vpc_endpoint_type       = "Interface" 

  tags = {
    Name = "ssmmessages-interface-endpoint"
  }
}

data "aws_region" "current" {
  provider = aws
}
