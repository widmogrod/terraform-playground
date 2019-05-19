provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_instance" "example" {
  ami           = "${lookup(var.amis, var.aws_region)}"
  instance_type = "t2.micro"
  # depends_on = ["aws_s3_bucket.examplee"]

  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
}

# resource "aws_s3_bucket" "examplee" {
#   bucket = "gabhab123"
#   acl    = "private"
# }

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}

# module "consul" {
#   source = "hashicorp/consul/aws"
#
#   num_servers = "3"
# }
#
# output "consul_server_asg_name" {
#   value = "${module.consul.asg_name_servers}"
# }
