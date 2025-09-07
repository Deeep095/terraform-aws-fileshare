

module "fileshare" {
    source = "../../terraform-fileshare-module"
    notify_email = "your-email-id"
    aws_region = "preferred-aws-region"
}

