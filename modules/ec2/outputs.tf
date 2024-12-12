output "private_instance_ip" {
  value = aws_instance.private_instance.private_ip
}

output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}