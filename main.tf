variable github_token {}
variable github_organization {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "cicd" {
  source = "./github/"

	github_token        = "${var.github_token}"
	github_organization = "${var.github_organization}"

}

output "payload_url" {
	value = "${module.cicd.payload_url}"
}
