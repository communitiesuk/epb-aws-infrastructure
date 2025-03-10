resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.bastion.id,
  ]

  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.bastion.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = var.tag
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }

  provisioner "local-exec" {
    command = <<-EOH
          sudo apt update
          sudo apt install postgresql postgresql-contrib
          sudo apt-get install redis-tools
        EOH
  }
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

  owners = ["099720109477"] # Canonical
}
