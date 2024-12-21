resource "random_password" "db_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric  = true
  override_special = "_%@"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security Group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = var.private_subnet_cidrs
    from_port   = 5432  
    to_port     = 5432
    protocol    = "tcp"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags = {
    Name = "RDS-Security-Group"
  }
}

resource "aws_db_instance" "postgresql" {
  identifier        = "my-postgres-db"
  engine            = "postgres"
  engine_version    = "13.3"
  instance_class    = "db.t3.micro" 
  allocated_storage = 20  
  storage_type      = "gp2"
  username          = var.db_username
  password          = random_password.db_password.result
  db_name           = var.db_name
  port              = 5432
  publicly_accessible = false
  multi_az          = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot = true
  tags = {
    Name = "MyPostgresDB"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "RDS subnet group for private subnets"

  tags = {
    Name = "RDS-Subnet-Group"
  }
}

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "my-postgres-db-credentials"
  description = "PostgreSQL credentials for the RDS instance"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result  
    db_name  = var.db_name
    host     = aws_db_instance.postgresql.address
    port     = "5432"
  })
}

