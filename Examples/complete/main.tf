
module "fileshare" {
  source = "./modules"

  notify_email = "your-email-id"
  aws_region   = "preferred-aws-region"
}