terraform {
  backend "s3" {
    bucket       = "eks-cicd-project-tfstate-607780587351"
    key          = "dev/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
