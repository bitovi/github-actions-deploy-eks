# Backend configuration is loaded early so we can't use variables
terraform {
  backend "s3" {
    region  = "us-east-1"
    bucket  = "bitovi-eks-statefile"
    key     = "terraform.tfstate"
    encrypt = true #AES-256 encryption
  }
}