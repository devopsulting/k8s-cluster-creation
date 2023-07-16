terraform {
  backend "s3" {
    bucket = "k8s-infra-creation"
    key    = "tfstate/k8sprod.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state"
  }
}