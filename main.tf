provider "aws" {
  region = "ap-northeast-2"
  profile = "default"
}

# 기본 네트워크 인프라 구성
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone  = "ap-northeast-2a"
}

# EC2 인스턴스 구성
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id           = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_id
  public_subnet_id  = module.vpc.public_subnet_id
  key_name         = "test"
}