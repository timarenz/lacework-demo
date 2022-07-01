variable "environment_name" {
  description = "Used as value of environment tag to identified resources in AWS."
  type        = string
}

variable "owner_name" {
  description = "Used as value of owner tag to identified resources in AWS."
  type        = string
}

variable "aws_region" {
  description = "AWS region where you want to deploy this EKS cluster."
  type        = string
  default     = "eu-central-1"
}

variable "lacework_agent_server_url" {
  description = "Lacework API Url the agent should connect to. By default the US region is used (`https://api.lacework.net`). If you are using the EU region, use `https://api.fra.lacework.net` as value."
  type        = string
  default     = "https://api.lacework.net"
}

variable "lacework_linux_agent_install_script_url" {
  type    = string
  default = "https://updates.lacework.net/5.7.0.8548_2022-06-25_release-v5.7_621e2b2ac38145e22ea251570c3ee72e8ad4fc67/install.sh"
}

variable "lacework_linux_agent_version" {
  type    = string
  default = "latest"
}

variable "lacework_windows_agent_msi_url" {
  type    = string
  default = "https://updates.lacework.net/windows/GA-1.0.0.2345/LWDataCollector.msi"
}

variable "lacework_linux_agent_token_name" {
  description = "Name of the Lacework linux agent token to use to deploy the Lacework agent. This token will not be created using Terraform and there has to be preexisting in your Lacework account."
  type        = string
}

variable "lacework_windows_agent_token_name" {
  description = "Name of the Lacework linux agent token to use to deploy the Lacework agent. This token will not be created using Terraform and there has to be preexisting in your Lacework account."
  type        = string
}
