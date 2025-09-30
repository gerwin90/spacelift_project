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

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
  # No default - must be provided by caller
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)"
  type        = string
  # No default - must be provided by caller
}
