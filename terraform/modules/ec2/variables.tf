variable "region" {
  description = "Region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where EC2 instances and ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of IDs of the public subnets where the ALB will be deployed"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of IDs of the private subnets where the EC2 instances will be deployed"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key for connecting to EC2 instances (optional)"
  type        = string
  default     = ""
}


