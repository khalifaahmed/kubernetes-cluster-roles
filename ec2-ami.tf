# Get latest AMI ID for Amazon Linux2 OS

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"] # Windows_Server-2022-English-Full-Base*
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#output "windows_ami_id_in_this_region" {
#  value = data.aws_ami.windows.image_id
#}

#
#data "aws_ami" "nat_instance" {
#  most_recent = true
#  owners      = ["amazon"]
#  filter {
#    name   = "name"
#    values = ["amzn-ami-vpc-nat-*"]
#  }
#  filter {
#    name   = "root-device-type"
#    values = ["ebs"]
#  }
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#}
#
#output "redhat_nat_instance_id_in_this_region" {
#  value = data.aws_ami.nat_instance.image_id
#}


data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["RHEL-9.2.0_HVM-*-GP2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#output "redhat_ami_id_in_this_region" {
#  value = data.aws_ami.redhat.image_id
#}

data "aws_ami" "amzlinux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}