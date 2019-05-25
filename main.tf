
# Main
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
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
