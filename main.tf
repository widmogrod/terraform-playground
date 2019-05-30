terraform {
  required_version = "~> 0.12.0"

  backend "s3" {
    bucket    = "terraform-state-5155"
    key       = "playground/deployment.tfstate"
    region    = "eu-west-1"
  }
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "terraform-state-5155"
  acl    = "private"

  tags = {
    Name        = "terraform-state-s3"
    Managed     = "terraform"
  }
}

# Main
provider "aws" {
  region     = "${var.aws_region_name}"
  profile    = "${var.aws_profile}"
}

provider "github" {
  token        = "${var.github_token}"
  organization = "${var.github_organization}"
}

module "build" {
  source = "./aws-codebuild-github"
  name = "gh-test-ns"
  repo = "https://github.com/widmogrod/github-marketplace-playground.git"
}

output "gh_badge_url" {
  value = "${module.build.badge_url}"
}
