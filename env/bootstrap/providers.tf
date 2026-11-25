provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      Project     = "eks-cicd-project"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Purpose     = "TerraformRemoteState"
    }
  }
}
