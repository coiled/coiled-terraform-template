variable "coiled_account_id" {
  type        = string
  description = "The AWS account ID of the account controlled by Coiled (do not change this unless given explicit instructions to do so)"
  default     = "077742499581"
}

variable "coiled_workspace_name" {
  type        = string
  description = "The coiled workspace name you wish to use"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy to"
  default     = "us-east-2"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
