terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "terraform_aws_module_files-structure" {
  source = "./modules"

  notify_email = var.notify_email
  aws_region   = var.aws_region
  
}
