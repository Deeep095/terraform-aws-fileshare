output "fileshare_all_outputs" {
  description = "All outputs exposed by the module"
  value       = module.fileshare.all_outputs
  
}

# only wants bucket name
output "bucket_name" {
  description = "S3 bucket name for file storage"
  value       = module.fileshare.all_outputs.bucket_name
}

# only wants API Gateway invoke URL
output "api_url" {
  description = "Base URL for the HTTP API"
  value       = module.fileshare.all_outputs.api_invoke_url
}