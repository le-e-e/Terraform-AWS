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
    Name = "lee-private-instance-sg"
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
    Name = "lee-public-instance-sg"
  }
}

# 프라이빗 서브넷의 인스턴스 (도커 애플리케이션)
resource "aws_instance" "private_instance" {
  ami           = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2023
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
    Name = "lee-private-instance"
  }
}

# 퍼블릭 서브넷의 웹서버 인스턴스 (Nginx 프록시)
resource "aws_instance" "public_instance" {
  ami           = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2023
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
    Name = "lee-public-instance"
  }
}