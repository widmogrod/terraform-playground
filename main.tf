variable github_token {}
variable github_organization {}

# Main

module "cicd" {
  source = "./aws-codebuild-github/"

	github_token        = "${var.github_token}"
	github_organization = "${var.github_organization}"

}

output "payload_url" {
	value = "${module.cicd.payload_url}"
}
