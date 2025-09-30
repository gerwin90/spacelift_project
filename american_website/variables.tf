variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default    = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
  default = "twohumansonetailinamerica-bucket"
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
