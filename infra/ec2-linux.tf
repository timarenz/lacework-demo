resource "random_shuffle" "subnet" {
  input        = module.environment.public_subnet_ids
  result_count = 1
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.root}/ssh.key"
  file_permission = "0400"
}

resource "aws_key_pair" "ssh" {
  key_name   = var.environment_name
  public_key = tls_private_key.ssh.public_key_openssh
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

resource "aws_security_group" "egress" {
  name   = "${var.environment_name}-egress"
  vpc_id = module.environment.vpc_id

  egress {
    protocol         = "-1"
    from_port        = "0"
    to_port          = "0"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

resource "aws_security_group" "ssh" {
  name   = "${var.environment_name}-ssh"
  vpc_id = module.environment.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr_blocks = ["${local.current_ip}/32"]
    self        = true
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

resource "aws_security_group" "internal" {
  name   = "${var.environment_name}-internal"
  vpc_id = module.environment.vpc_id

  ingress {
    protocol  = "-1"
    from_port = "0"
    to_port   = "0"
    self      = true
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

data "lacework_agent_access_token" "linux" {
  name = var.lacework_linux_agent_token_name
}

resource "aws_instance" "ubuntu" {
  count                       = var.ec2_linux_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = random_shuffle.subnet.result[0]
  vpc_security_group_ids      = [aws_security_group.egress.id, aws_security_group.ssh.id, aws_security_group.internal.id]
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 16
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
    Name        = "${var.environment_name}-ubuntu-vm-${count.index}"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sSL ${var.lacework_linux_agent_install_script_url} > /tmp/install.sh",
      "chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh ${data.lacework_agent_access_token.linux.token} -U ${var.lacework_agent_server_url} -V ${var.lacework_linux_agent_version}",
      # "rm -rf /tmp/install.sh"
    ]
  }
}
