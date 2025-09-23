variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
  # No default - must be provided by caller
}

variable "index_file" {
  description = "Path to local index.html file to upload"
  type        = string
  # No default - must be provided by caller
}
