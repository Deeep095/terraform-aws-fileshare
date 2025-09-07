
module "fileshare" {
  source = "Deeep095/fileshare/aws"
  version = "~> 1.1"
  notification_email = "your-email-id"
  region = "preferred-aws-region"
}