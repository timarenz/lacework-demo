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
    cidr_blocks = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    self        = true
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
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = random_shuffle.subnet.result[0]
  vpc_security_group_ids      = [aws_security_group.egress.id, aws_security_group.ssh.id]
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 16
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
    Name        = "${var.environment_name}-ubuntu-vm"
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

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }

  owners = ["801119661308"] # Microsoft

}

resource "aws_security_group" "rdp" {
  name   = "${var.environment_name}-rdp"
  vpc_id = module.environment.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "3389"
    to_port     = "3389"
    cidr_blocks = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    self        = true
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

resource "aws_security_group" "winrm" {
  name   = "${var.environment_name}-winrm"
  vpc_id = module.environment.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "5986"
    to_port     = "5986"
    cidr_blocks = ["${lookup(jsondecode(data.http.current_ip.body), "ip")}/32"]
    self        = true
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
  }
}

data "lacework_agent_access_token" "windows" {
  name = var.lacework_windows_agent_token_name
}

resource "aws_instance" "windows" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t3.medium"
  subnet_id                   = random_shuffle.subnet.result[0]
  vpc_security_group_ids      = [aws_security_group.egress.id, aws_security_group.winrm.id, aws_security_group.rdp.id]
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true
  get_password_data           = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 64
  }

  tags = {
    environment = var.environment_name
    owner       = var.owner_name
    Name        = "${var.environment_name}-windows-vm"
  }

  user_data = file("${path.module}/files/winrm.txt")

  connection {
    type     = "winrm"
    host     = self.public_ip
    https    = true
    insecure = true
    use_ntlm = true
    user     = "Administrator"
    password = rsadecrypt(self.password_data, tls_private_key.ssh.private_key_pem)
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -sta -ExecutionPolicy Unrestricted -Command Invoke-WebRequest -Uri ${var.lacework_windows_agent_msi_url} -OutFile LWDataCollector.msi",
      "powershell.exe -sta -ExecutionPolicy Unrestricted -Command Start-Process msiexec.exe -ArgumentList \"/i\",\"LWDataCollector.msi\",\"ACCESSTOKEN=${data.lacework_agent_access_token.linux.token}\",\"SERVERURL=${var.lacework_agent_server_url}\",\"/passive\" -Wait"
    ]
  }
}

