terraform {
  backend "s3" {
    bucket       = "technova-tfstate-unifaat"
    key          = "aula-05/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
