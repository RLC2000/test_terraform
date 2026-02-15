variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "demo_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}

variable "subnet_cidr_block" {
  description = "subnets cidr"
  default     = "10.0.225.0/24"
  type        = string
}

variable "subnet_avlz" {
  description = "subnet avl zne"
  default     = "us-east-1a"
  type        = string
}

variable "subnet_launch_ip" {
  type    = bool
  default = true
}

variable "devops_name" {
  type    = string
  default = "Rasham"
}

variable "env" {
  description = "Alpha/beta/Gamma"
  default     = "beta"
  type        = string
}