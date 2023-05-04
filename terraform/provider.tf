terraform {
  required_version = ">= 0.13"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
/* 
provider "aws" {
  region  = "us-east-1"
  version = ">= 4.0"
  
  default_tags {
    tags = local.common_tags
  }
} */

provider "random" {
  version = "~> 2.2.1"
}
