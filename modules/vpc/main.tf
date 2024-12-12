# 1. VPC 생성
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "the-vpc"
  }
}

# 2. 서브넷 생성
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block             = var.public_subnet_cidr
  availability_zone      = var.availability_zone
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  
  tags = {
    Name = "private-subnet"
  }
}

# 3. 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "igw"
  }
}

# 4. 라우팅 테이블 - 퍼블릭
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. NAT 게이트웨이
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  
  tags = {
    Name = "nat-gateway"
  }
}

# 6. 라우팅 테이블 - 프라이빗
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# 7. NAT 게이트웨이 삭제 대기 설정
resource "time_sleep" "wait_for_nat_destroy" {
  depends_on = [aws_nat_gateway.nat_gateway]
  destroy_duration = "5m"
}