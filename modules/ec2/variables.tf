# 필수 변수 정의
variable "private_subnet_id" {
  description = "프라이빗 서브넷 ID"
  type        = string
}

variable "public_subnet_id" {
  description = "퍼블릭 서브넷 ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "key_name" {
  description = "EC2 키 페어 이름"
  type        = string
}