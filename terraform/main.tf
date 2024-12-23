module "vpc" {
  source = "./modules/vpc"
  vpc_name = "spring-petclinic-vpc"
  vpc_cidr_block = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

module "ec2" {
  source = "./modules/ec2"
  region = "us-east-1"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  ami_id = "ami-01816d07b1128cd2d" 
  instance_type = "t2.micro"
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  db_username = "springpetclinic"  
  db_name = "springpetclinic"      
}