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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  tags = {
    Name = "ec2-ssm-sg"
  }
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
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
  vpc_endpoint_type  = "Interface"

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
  vpc_endpoint_type  = "Interface"

  tags = {
    Name = "ssmmessages-interface-endpoint"
  }
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.kms"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  vpc_endpoint_type  = "Interface"

  tags = {
    Name = "kms-interface-endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.logs"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  vpc_endpoint_type  = "Interface"

  tags = {
    Name = "cloudwatch-logs-interface-endpoint"
  }
}

data "aws_region" "current" {
  provider = aws
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
