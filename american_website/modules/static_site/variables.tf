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
  default     = "twohumansonetailinamerica.com"
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)"
  type        = string
  default     = "arn:aws:acm:us-east-1:310649825077:certificate/c3b9ce2e-6f9f-4b09-a339-3f2249dbb668"
}
