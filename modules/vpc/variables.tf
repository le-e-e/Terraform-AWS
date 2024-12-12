variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "public_subnet_cidr" {
  description = "퍼블릭 서브넷 CIDR"
  type        = string
}

variable "private_subnet_cidr" {
  description = "프라이빗 서브넷 CIDR"
  type        = string
}

variable "availability_zone" {
  description = "가용영역"
  type        = string
}