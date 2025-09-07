this is the readme file for the example

sample code

```
module "fileshare_name" {
    source = "../../terraform-fileshare-module"
    notify_email = "your-email-id"
    aws_region = "preferred-aws-region"
    
}
```