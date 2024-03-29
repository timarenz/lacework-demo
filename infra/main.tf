provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "http" "current_ip" {
  url = "https://4.icanhazip.com/"
}

resource "random_id" "id" {
  byte_length = 3
}

locals {
  name       = "${var.owner_name}-${var.environment_name}-${random_id.id.hex}"
  current_ip = chomp(data.http.current_ip.body)
}

module "environment" {
  source           = "git::https://github.com/timarenz/terraform-aws-environment.git?ref=v0.1.3"
  name             = local.name
  environment_name = var.environment_name
  owner_name       = var.owner_name
  public_subnets = [
    {
      "name" : "public-subnet-0",
      "prefix" : "192.168.30.0/24",
      "tags" : {
        "kubernetes.io/role/elb" : "1"
      }
      }, {
      "name" : "public-subnet-1",
      "prefix" : "192.168.31.0/24",
      "tags" : {
        "kubernetes.io/role/elb" : "1"
      }
      }, {
      "name" : "public-subnet-2",
      "prefix" : "192.168.32.0/24",
      "tags" : {
        "kubernetes.io/role/elb" : "1"
      }
    }
  ]
  private_subnets = [
    { "name" : "private-subnet-0",
      "prefix" : "192.168.40.0/24",
      "tags" : {
        "kubernetes.io/role/internal-elb" : "1"
      }
      }, {
      "name" : "private-subnet-1",
      "prefix" : "192.168.41.0/24",
      "tags" : {
        "kubernetes.io/role/internal-elb" : "1"
      }
      }, {
      "name" : "private-subnet-2",
      "prefix" : "192.168.42.0/24",
      "tags" : {
        "kubernetes.io/role/internal-elb" : "1"
      }
    }
  ]
}
