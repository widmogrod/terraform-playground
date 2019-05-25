# IMPORTANT: You need manualy authorasie CodeBuild app in github

provider "github" {
	token        = "${var.github_token}"
	organization = "${var.github_organization}"
}

resource "aws_codebuild_webhook" "example" {
	# project_name = "${aws_codebuild_project.example.name}"
	project_name = "gh-test"
}

# resource "github_repository_webhook" "example" {
# 	# repository = "${github_repository.repo.name}"
# 	# name = "example-aws-wh"
# 	repository = "github-marketplace-playground"
#
# 	configuration {
# 		url          = "${aws_codebuild_webhook.example.payload_url}"
# 		secret       = "${aws_codebuild_webhook.example.secret}"
# 		content_type = "json"
# 		insecure_ssl = false
# 	}
#
# 	active = true
# 	events = ["push"]
# }

output "payload_url" {
	value = "${aws_codebuild_webhook.example.payload_url}"
}
