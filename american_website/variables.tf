variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
  default = "our-american-website-bucket"
}