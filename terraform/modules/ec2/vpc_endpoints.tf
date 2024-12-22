resource "aws_vpc_endpoint" "ssm" {
  vpc_id = var.vpc_id  
  service_name = "com.amazonaws.${var.region}.ssm"
  route_table_ids = var.private_route_table_ids  

  subnet_ids = var.private_subnet_ids  

  dns_entry {
    dns_name = "ssm.${var.region}.amazonaws.com"
    hosted_zone_id = "com.amazonaws.${var.region}.ssm"
  }

  tags = {
    Name = "SSM Endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id = var.vpc_id  
  service_name = "com.amazonaws.${var.region}.ssmmessages"
  route_table_ids = var.private_route_table_ids  

  subnet_ids = var.private_subnet_ids  

  dns_entry {
    dns_name = "ssmmessages.${var.region}.amazonaws.com"
    hosted_zone_id = "com.amazonaws.${var.region}.ssmmessages"
  }

  tags = {
    Name = "SSM Messages Endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id = var.vpc_id  
  service_name = "com.amazonaws.${var.region}.ec2messages"
  route_table_ids = var.private_route_table_ids  

  subnet_ids = var.private_subnet_ids  

  dns_entry {
    dns_name = "ec2messages.${var.region}.amazonaws.com"
    hosted_zone_id = "com.amazonaws.${var.region}.ec2messages"
  }

  tags = {
    Name = "EC2 Messages Endpoint"
  }
}
