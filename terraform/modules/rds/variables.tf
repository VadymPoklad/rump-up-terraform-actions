variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where the RDS instance will be placed"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets for access control"
  type        = list(string)
}

variable "db_username" {
  description = "Username for the PostgreSQL database"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "mydb"
}
