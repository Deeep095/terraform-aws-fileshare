

module "fileshare" {
    source = "../../terraform-fileshare-module"
    notify_email = "your-email-id"
    aws_region = "preferred-aws-region"  #optional, default is us-east-1
    bucket_prefix = "your-unique-bucket-prefix" #optional, default is bucket-s3-files
}

