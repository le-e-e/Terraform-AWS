provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone  = "ap-northeast-2a"
}

module "ec2" {
  source = "./modules/ec2"
  
  private_subnet_id = module.vpc.private_subnet_id
  public_subnet_id  = module.vpc.public_subnet_id
  vpc_id           = module.vpc.vpc_id
  key_name         = "your-key-name"  # 여기에 실제 키 페어 이름을 입력하세요
}

module "alb" {
  source = "./modules/alb"
  
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_id
  instance_id       = module.ec2.instance_id
} 