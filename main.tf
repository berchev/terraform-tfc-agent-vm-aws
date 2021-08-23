################ VARIABLES ################
# variable "terraform_version" {
#   default = "1.0.5"
# }

# variable "tfc_agent_version" {
#   default = "0.4.0"
# }

variable "region" {
  default = "us-east-1"
}
variable "vpc_cidr_block" {
  default = "16.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  default = "16.0.16.0/24"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "vpc_route_table_cidr_block" {
  default = "0.0.0.0/0"
}

variable "key_name" {
  default = "berchev_key_pair"
}

################ PROVIDER ################
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner = "Georgiman"
    }
  }
}

################ NETWORKING ################
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "georgiman_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
}

# Creating first subnet for the database
resource "aws_subnet" "georgiman_public_subnet" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.georgiman_vpc.id
  cidr_block        = var.public_subnet_cidr_block
}

#Creating gateway for specific VPC (In this way traffic from internet can go in/out of the VPC)
resource "aws_internet_gateway" "georgiman_gw" {
  vpc_id = aws_vpc.georgiman_vpc.id
}

# Creating route table for specific VPC
resource "aws_route_table" "georgiman_route_table" {
  vpc_id = aws_vpc.georgiman_vpc.id

  route {
    cidr_block = var.vpc_route_table_cidr_block
    gateway_id = aws_internet_gateway.georgiman_gw.id
  }
}

# Assign route table to specific VPC
resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.georgiman_vpc.id
  route_table_id = aws_route_table.georgiman_route_table.id
}

# Assign route table to subnet, in order to make it public
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.georgiman_public_subnet.id
  route_table_id = aws_route_table.georgiman_route_table.id
}

################ INSTANCE ################
resource "aws_security_group" "georgiman_sg" {
  name        = "georgiman_sg"
  description = "Allow everything"
  vpc_id      = aws_vpc.georgiman_vpc.id
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.georgiman_sg.id
}


resource "aws_security_group_rule" "egress" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.georgiman_sg.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "template_file" "bootstrap_sh" {
  template = file("${path.root}/scripts/bootstrap.sh")

  #   vars = {
  #     TERRAFORM_VERSION = var.terraform_version
  #     TFC_AGENT_VERSION = var.tfc_agent_version
  #   }
}

data "template_cloudinit_config" "tfc_agent_setup" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
packages:
- jq
- curl
- unzip
write_files:
  - content: |
      ${base64encode("${data.template_file.bootstrap_sh.rendered}")}
    encoding: b64
    owner: root:root
    path: /tmp/bootstrap.sh
    permissions: '0777'
runcmd:
- ["/bin/bash", "-c", "/tmp/bootstrap.sh"]
EOF
  }

  part {
    content = data.template_file.bootstrap_sh.rendered
  }

}

resource "aws_instance" "agent_vm_1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.georgiman_public_subnet.id
  key_name                    = var.key_name
  security_groups             = [aws_security_group.georgiman_sg.id]
  user_data_base64            = data.template_cloudinit_config.tfc_agent_setup.rendered
  associate_public_ip_address = true
}

# Uncomment in case of 2nd VM (agent is needed)
# resource "aws_instance" "agent_vm_2" {
#   ami              = data.aws_ami.ubuntu.id
#   instance_type    = var.instance_type
#   subnet_id        = aws_subnet.georgiman_public_subnet.id
#   key_name         = var.key_name
#   security_groups  = [aws_security_group.georgiman_sg.id]
#   user_data_base64 = data.template_cloudinit_config.tfc_agent_setup.rendered
#   associate_public_ip_address = true
# }

######### OUTPUTS #############
output "VM1" {
  value = aws_instance.agent_vm_1.public_dns
}

# output "VM2" {
#     value = aws_instance.agent_vm_2.public_dns
# }
