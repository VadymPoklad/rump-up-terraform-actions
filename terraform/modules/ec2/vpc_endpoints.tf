resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.ssm"
  route_table_ids   = var.private_route_table_ids
  policy            = jsonencode({
                        Version = "2012-10-17",
                        Statement = [
                          {
                            Effect = "Allow"
                            Action = "*"
                            Resource = "*"
                          }
                        ]
                      })

  tags = {
    Name = "ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  route_table_ids   = var.private_route_table_ids
  policy            = jsonencode({
                        Version = "2012-10-17",
                        Statement = [
                          {
                            Effect = "Allow"
                            Action = "*"
                            Resource = "*"
                          }
                        ]
                      })

  tags = {
    Name = "ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.ec2messages"
  route_table_ids   = var.private_route_table_ids
  policy            = jsonencode({
                        Version = "2012-10-17",
                        Statement = [
                          {
                            Effect = "Allow"
                            Action = "*"
                            Resource = "*"
                          }
                        ]
                      })

  tags = {
    Name = "ec2messages-endpoint"
  }
}
