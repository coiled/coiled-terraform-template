
provider "aws" {
  region = var.aws_region
}

provider "random" {
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


locals {
  common_tags = {
    terraform         = true
    CoiledEnvironment = "prod"
  }
  current_region     = data.aws_region.current.name
  current_account_id = data.aws_caller_identity.current.account_id
}
