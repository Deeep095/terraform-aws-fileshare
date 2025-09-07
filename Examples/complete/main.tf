terraform{
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
}

provider "aws" {
  region = "preferred-aws-region" 
}

module "fileshare" {
  source = "./modules"

  notify_email = "your-email-id"
  
}