output "ubuntu_vm_public_ip" {
  value = aws_instance.ubuntu[*].public_ip
}

# output "windows_vm_public_ip" {
#   value = aws_instance.windows.public_ip
# }

# output "windows_vm_password" {
#   value     = rsadecrypt(aws_instance.windows.password_data, tls_private_key.ssh.private_key_pem)
#   sensitive = true
# }

