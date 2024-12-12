# EC2 인스턴스 IP 출력
output "private_instance_ip" {
  value = aws_instance.private_instance.private_ip
}

output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}

output "bastion_public_ip" {
  value = aws_spot_instance_request.bastion.public_ip
}