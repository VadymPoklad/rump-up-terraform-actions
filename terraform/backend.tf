terraform {
  backend "s3" {
    bucket         = "tfstate-rump-up-actions"           
    key            = "terraform.tfstate"       
    region         = "us-east-1"                 
    encrypt        = true                        
    dynamodb_table = "tfstate-rump-up-actions"          
    acl            = "private"                   
  }
}