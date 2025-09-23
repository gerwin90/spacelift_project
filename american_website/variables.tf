variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
  # No default - force users to provide their own unique name
}