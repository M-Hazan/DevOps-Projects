terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    organization = "M-Hazan"

    workspaces {
      name = "Hazcorp-reborn"
    }
  }
}

provider "aws" {
  region = "il-central-1"
  skip_region_validation = true
}