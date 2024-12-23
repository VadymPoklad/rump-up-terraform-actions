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

  depends_on = [aws_iam_role.ec2_ssm_role]

  tags = {
    Name = "ec2-ssm-sg"
  }
}

resource "aws_lb" "application_load_balancer" {
  name                        = "app-lb"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.ec2_sg.id]
  subnets                     = var.subnet_ids
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
  count               = length(var.subnet_ids)
  target_group_arn    = aws_lb_target_group.target_group.arn
  target_id           = aws_instance.ec2_instances[count.index].id
  port                = 8080

  depends_on = [aws_lb_listener.http_listener]
}

resource "aws_instance" "ec2_instances" {
  count                  = length(var.subnet_ids)
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(var.subnet_ids, count.index)
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

  depends_on = [aws_iam_role.ec2_ssm_role]
}