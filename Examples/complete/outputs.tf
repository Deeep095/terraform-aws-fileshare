output "fileshare_all_outputs" {
  description = "All outputs exposed by the module"
  value       = module.module.all_outputs
  
}

# only wants bucket name
output "bucket_name" {
  description = "S3 bucket name for file storage"
  value       = module.module.all_outputs.bucket_name
}