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
  default = "https://updates.lacework.net/5.8.0.8786_2022-07-26_release-v5.8_6b21f03fede4262d0804e644119e1a16b42a86a4/install.sh"
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

variable "ec2_linux_count" {
  description = "Number of Ubuntu EC2 instances to deploy that run the Lacework agent"
  type        = number
  default     = 0
}

variable "existing_s3_bucket" {
  description = "Name of the existing S3 bucket used by CloudTrail."
  type        = string
}

variable "existing_sns_topic" {
  description = "Name of the existing SNS topic used by CloudTrail."
  type        = string
}

variable "k8s_admin_role" {
  description = "Map that contains the name and arn of an AWS role you want to assign the cluster-admin role in the EKS cluster. Example: `{ name = \"admin\", arn = \"rn:aws:iam::123456789012:role/eks-admin-role\" }`."
  type        = map(string)
  #   default = {
  #   name = "admin"
  #   arn  = "arn:aws:iam::123456789012:role/eks-admin-role"
  # }
}

variable "node_instance_type" {
  description = "EC2 instance type for the K8s nodes."
  type        = string
  default     = "t3.medium"
}

variable "lacework_eks_agent_token_name" {
  description = "Name of the Lacework EKS agent token to use to deploy the Lacework agent. This token will not be created using Terraform and there has to be preexisting in your Lacework account."
  type        = string
}
