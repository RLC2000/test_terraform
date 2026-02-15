# Configure the AWS Provider
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["C:\\Users\\rasha\\OneDrive\\Desktop\\Terraform\\Tf_basics\\credentials"]
  default_tags {
    tags = {
      Environment = terraform.workspace
    }
  }
}

#Retrieve the list of AZs in the current AWS region

data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#Define the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
  }
}

#Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Deploy the public subnets
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Create route tables for public and private subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    #nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_public_rtb"
    Terraform = "true"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    # nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_private_rtb"
    Terraform = "true"
  }
}

#Create route table associations
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
}

#Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "demo_igw"
  }
}

#Create EIP for NAT Gateway
# resource "aws_eip" "nat_gateway_eip" {
#   domain     = "vpc"
#   depends_on = [aws_internet_gateway.internet_gateway]
#   tags = {
#     Name = "demo_igw_eip"
#   }
# }

#Create NAT Gateway
# resource "aws_nat_gateway" "nat_gateway" {
#   depends_on    = [aws_subnet.public_subnets]
#   allocation_id = aws_eip.nat_gateway_eip.id
#   subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
#   tags = {
#     Name = "demo_nat_gateway"
#   }
# }

# #Creating a AWS Instance
# resource "aws_instance" "web" {
#   ami                    = "ami-01cc34ab2709337aa"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.public_subnets["public_subnet_1"].id

#   key_name = aws_key_pair.generated.key_name
#   tags = {
#     "Identity" = "Value1"
#   }

# }


#create a S3 bucket
# resource "aws_s3_bucket" "my-new-S3-bucket" {
#   bucket = "rasham${random_id.rand.hex}"
#   tags={
#     Name="Test"
#     Purpose="Test"
#   }
# }

#security group

resource "aws_security_group" "sg1" {
  name        = "rashamtest"
  description = "test"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    to_port     = 445
    from_port   = 443
    cidr_blocks = ["0.0.0.0/0", "11.22.33.44/32"]
    protocol    = "tcp"
  }
  tags = {
    Name = "RASHAM"
  }
}

resource "random_id" "rand" {
  byte_length = 16
}

#subnet with variables

resource "aws_subnet" "variables-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.subnet_avlz
  map_public_ip_on_launch = var.subnet_launch_ip

  tags = {
    Name = "Testing done be ${var.devops_name}"
  }
}

locals {
  team        = "rasham_testing_terraform"
  application = "api_backend"
  server_name = "ec2-${var.subnet_avlz}-${var.env}"
}

#DATA BLOCK AMI_ID

data "aws_ami" "check_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.10.20260120.4-kernel-6.1-x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

}

# #Creating a EC2 Instace:

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.check_ami.id
  instance_type               = "t3.micro"
  security_groups             = [aws_security_group.ssh_sg.id, aws_security_group.web_sg.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  key_name                    = aws_key_pair.generated.key_name
  tags                        = local.common_tags
  connection {
    user        = "ec2-user"
    private_key = tls_private_key.generate.private_key_pem
    host        = self.public_ip
  }

  ##PROVISIONER

  provisioner "local-exec" {
    command    = "chmod 600 ${local_file.private_key_pem.filename}"
    on_failure = continue
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y", "sudo systemctl start httpd"
    ]


  }

}
resource "tls_private_key" "generate" {
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.generate.private_key_pem
  filename = "MYAWSKey.pem"
}

resource "aws_key_pair" "generated" {
  key_name   = "MYAWSKey"
  public_key = tls_private_key.generate.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

resource "aws_security_group" "ssh_sg" {
  description = "Security group SSH"
  name        = "allow-all-ssh"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    to_port     = 22
    from_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  description = "Web traffic control"
  name        = "web_sg"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    to_port     = 80
    from_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  ingress {
    to_port     = 443
    from_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
}

# ## IMPORTS..

# resource "aws_instance" "aws_linux" {
#   ami           = "ami-0532be01f26a3de55"
#   instance_type = "t3.micro"
# }


# ## MODULE 

# module "server" {
#   source = "./server"
#   ami=data.aws_ami.check_ami.id
#   subnet_id = aws_subnet.public_subnets["public_subnet_3"].id
#   security_groups = [aws_security_group.ssh_sg.id,aws_security_group.ssh_sg.id]
# }

# output "instance_ip"{
#   value = module.server.public_ip
# }
# output "public_dns_1" {
#   value = module.server.public_dns
#   }


#   module "server_2" {
#   source = "./server"
#   ami=data.aws_ami.check_ami.id
#   subnet_id = aws_subnet.public_subnets["public_subnet_3"].id
#   security_groups = [aws_security_group.ssh_sg.id,aws_security_group.ssh_sg.id]
# }

# module "the_module_server" {
#   source          = "./module"
#   subnet_id       = aws_subnet.public_subnets["public_subnet_1"].id
#   ami             = data.aws_ami.check_ami.id
#   security_groups = [aws_security_group.web_sg.id, aws_security_group.ssh_sg.id]
#   localkey        = tls_private_key.generate.private_key_pem
#   key_name = aws_key_pair.generated.key_name
# }

# output "module_connect" {
#   value = module.the_module_server.module_server_ip
# }


################## TERRAFROM MODULE FROM TERRAFORM REPO

# module "autoscaling" {
#   source  = "terraform-aws-modules/autoscaling/aws"
#   version = "9.1.0"
#   # insert the 1 required variable here
#   name="myasg"
#   vpc_zone_identifier = [aws_subnet.public_subnets["public_subnet_1"].id,aws_subnet.public_subnets["public_subnet_2"].id]
#   min_size = 0
#   max_size = 1
#   desired_capacity = 1

#   # launch template
#   create_launch_template = true

#   image_id = data.aws_ami.check_ami.id
#   instance_type = "t3.micro"

# }



# module "autoscaling" {
#   source = "github.com/terraform-aws-modules/terraform-aws-autoscaling"
#   # insert the 1 required variable here
#   name                = "myasg"
#   vpc_zone_identifier = [aws_subnet.public_subnets["public_subnet_1"].id, aws_subnet.public_subnets["public_subnet_2"].id]
#   min_size            = 0
#   max_size            = 1
#   desired_capacity    = 1

#   # launch template
#   create_launch_template = true

#   image_id      = data.aws_ami.check_ami.id
#   instance_type = "t3.micro"

# }

# output "mx_size" {
#   value = module.autoscaling.autoscaling_group_max_size
# }

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"
}

output "s3_arn" {
  value = module.s3-bucket.s3_bucket_arn
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "6.6.0"
  azs                = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
}

locals {
  service_name = "api_test"
  app_team     = "Cloud Team"
  createdby    = "terraform"
}

locals {
  common_tags = {
    Name             = "Rasham"
    Terraform        = "true"
    "environment is" = "dev"
    "service_name"   = local.service_name
    app_team         = local.app_team
    createdby        = local.createdby
  }
}


variable "env1" {
  type = map(any)
  default = {
    "prod" = {
      ip = "10.0.100.0/24"
      az = "us-east-1a"
    }
    "dev" = {
      ip = "10.0.250.0/24"
      az = "us-east-1b"
    }
  }
}

resource "aws_subnet" "sb" {
  vpc_id            = aws_vpc.vpc.id
  for_each          = var.env1
  cidr_block        = each.value["ip"]
  availability_zone = each.value["az"]
}

locals {
  ingress_rule = [{
    port        = 443
    description = "port 443"
    }, {
    port        = 80
    description = "port 80"
  }]
}

resource "aws_security_group" "sg_test_1" {
  vpc_id = aws_vpc.vpc.id
  name   = "testing_sg"
  dynamic "ingress" {
    for_each = local.ingress_rule
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "ingress" {
  type = map(any)
  default = {
    "80" = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    "443" = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

}

resource "aws_security_group" "sg_test_2" {
  vpc_id = aws_vpc.vpc.id
  name   = "testing_sg"
  dynamic "ingress" {
    for_each = var.ingress
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}


