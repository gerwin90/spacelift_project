variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default    = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
  default = "our-american-website-bucket"
}