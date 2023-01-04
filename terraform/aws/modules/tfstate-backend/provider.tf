terraform {
  backend "s3" {
    region         = "us-east-2"
    bucket         = "homeops-dev-use2-terraform-backend"
    key            = "homeops/modules/tfstate-backend/terraform.tfstate"
    dynamodb_table = "terraform-lock"
    role_arn       = "arn:aws:iam::403612620603:role/terraform-backend"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.3"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
}

data "sops_file" "aws" {
  source_file = "secret.sops.yaml"
}

provider "aws" {
  region     = "us-east-2"
  access_key = data.sops_file.aws.data["aws_access_key"]
  secret_key = data.sops_file.aws.data["aws_secret_key"]
}
