resource "aws_vpc_endpoint" "ssm" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssm"
  route_table_ids = [for subnet in aws_subnet.private_subnets : aws_route_table.private_route_table.id]

  tags = {
    Name = "ssm-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  route_table_ids = [for subnet in aws_subnet.private_subnets : aws_route_table.private_route_table.id]

  tags = {
    Name = "ec2messages-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  route_table_ids = [for subnet in aws_subnet.private_subnets : aws_route_table.private_route_table.id]

  tags = {
    Name = "ssmmessages-vpc-endpoint"
  }
}

data "aws_region" "current" {
  provider = aws
}
