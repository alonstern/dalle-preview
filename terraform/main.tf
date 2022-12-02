terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
 region = "eu-west-1"
}

# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-1"
  profile = "Alon"
}

variable "dalle_api_key" {
  description = "API key to access Dalle 2"
  type        = string
}

variable "domain" {
  description = "The domain name for the web service"
  type        = string
}

module "db" {
  source = "./modules/db"
}

module "lambda" {
  source = "./modules/lambda"
  dalle_api_key = var.dalle_api_key
  bucket_arn = module.db.bucket_arn
}

data "aws_caller_identity" "current" {}

module "gateway" {
  source = "./modules/gateway"
  lambda_function_name = module.lambda.lambda_function_name
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  region = local.region
  account_id = data.aws_caller_identity.current.account_id
  domain = var.domain
}
