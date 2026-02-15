terraform {
  # backend "s3"{
  #   bucket="rasham-terraform-state"
  #   key="statefiles/prodstate"
  #   region = "us-east-1"
  #   shared_credentials_files =  ["C:\\Users\\rasha\\OneDrive\\Desktop\\Terraform\\Tf_basics\\credentials"]

  #   dynamodb_table = "locktable-terraform"
  #   encrypt = true
  # }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "LearningTerraform_Associate"
    workspaces {
      name = "my-aws"
    }
  }

  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>2.1.0"
    }
    local = {
      source = "hashicorp/local"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

