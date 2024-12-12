#######################
# 1. Security Groups
#######################

# 프라이빗 인스턴스용 보안 그룹
resource "aws_security_group" "private_instance_sg" {
  name        = "private-instance-sg"
  description = "Security group for private instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_instance_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-instance-sg"
  }
}

# 퍼블릭 웹서버용 보안 그룹
resource "aws_security_group" "public_instance_sg" {
  name        = "public-instance-sg"
  description = "Security group for public instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-instance-sg"
  }
}

# Bastion Host 보안 그룹
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# 프라이빗 인스턴스 SSH 접근 규칙
resource "aws_security_group_rule" "private_instance_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_instance_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

#######################
# 2. EC2 Instances
#######################

# 프라이빗 서브넷의 웹 서버
resource "aws_instance" "private_instance" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"
  subnet_id     = var.private_subnet_id
  key_name      = var.key_name
  
  vpc_security_group_ids = [aws_security_group.private_instance_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              docker pull your-flask-app:latest
              docker run -d -p 80:80 your-flask-app:latest
              EOF

  tags = {
    Name = "private-web-server"
  }
}

# 퍼블릭 서브넷의 Nginx 프록시
resource "aws_instance" "public_instance" {
  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name
  
  vpc_security_group_ids = [aws_security_group.public_instance_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              
              cat > /etc/nginx/conf.d/proxy.conf <<'EOL'
              server {
                  listen 80;
                  location / {
                      proxy_pass http://${aws_instance.private_instance.private_ip};
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                  }
              }
              EOL
              
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "nginx-proxy"
  }
}

# Bastion Host (스팟 인스턴스)
resource "aws_spot_instance_request" "bastion" {
  ami                    = "ami-0c9c942bd7bf113a2"
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  
  spot_type = "persistent"
  spot_price = "0.0035"
  
  wait_for_fulfillment = true
  
  tags = {
    Name = "bastion-host"
  }

  instance_interruption_behavior = "terminate"
}

# Bastion Host 태그 설정
resource "aws_ec2_tag" "bastion_tags" {
  resource_id = aws_spot_instance_request.bastion.spot_instance_id
  key         = "Name"
  value       = "bastion-host"

  depends_on = [aws_spot_instance_request.bastion]
}