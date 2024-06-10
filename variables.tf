
variable "VPC_NAME" {
  description = "The name of the VPC"
  default     = "NC2-VPC"
}

variable "AWS_REGION" {
  description = "The AWS region to deploy to"
  default     = "us-west-2"     # eu-west-3	= Paris Region
}