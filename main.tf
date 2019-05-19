variable github_token {}
variable github_organization {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_vpc" "vpcity" {
  cidr_block       = "10.0.0.0/21"
  instance_tenancy = "default"

  tags = {
    Name = "vpcity"
  }
}

resource "aws_subnet" "vpcity-a-public" {
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.aws_region}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-public"
  }
}

resource "aws_subnet" "vpcity-a-private" {
  cidr_block        = "10.0.1.128/26"
  availability_zone = "${var.aws_region}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-private"
  }
}

resource "aws_subnet" "vpcity-a-db" {
  cidr_block        = "10.0.1.0/25"
  availability_zone = "${var.aws_region}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-db"
  }
}

resource "aws_subnet" "vpcity-a-spare" {
  cidr_block        = "10.0.1.192/26"
  availability_zone = "${var.aws_region}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-spare"
  }
}

# PUBLIC
resource "aws_internet_gateway" "vpcity-public-roads-igw" {
  vpc_id = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-public-roads-igw"
  }
}

resource "aws_route_table" "vpcity-public-roads" {
  vpc_id = "${aws_vpc.vpcity.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpcity-public-roads-igw.id}"
  }

  tags = {
    Name = "vpcity-public-roads"
  }
}

resource "aws_route_table_association" "vpcity-a-public" {
  subnet_id      = "${aws_subnet.vpcity-a-public.id}"
  route_table_id = "${aws_route_table.vpcity-public-roads.id}"
}

 # PRIVATE
resource "aws_eip" "vpcity-nat" {
  vpc      = true

  tags = {
    Name = "vpcity-eip"
  }
}

resource "aws_nat_gateway" "vpcity-gw" {
  allocation_id = "${aws_eip.vpcity-nat.id}"
  subnet_id     = "${aws_subnet.vpcity-a-public.id}"

	depends_on = ["aws_internet_gateway.vpcity-public-roads-igw"]

  tags = {
    Name = "vpcity-nat-gw"
  }
}

resource "aws_route_table" "vpcity-private-roads" {
  vpc_id = "${aws_vpc.vpcity.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.vpcity-gw.id}"
  }

  tags = {
    Name = "vpcity-private-roads"
  }
}

resource "aws_route_table_association" "vpcity-private" {
  subnet_id      = "${aws_subnet.vpcity-a-private.id}"
  route_table_id = "${aws_route_table.vpcity-private-roads.id}"
}
resource "aws_route_table_association" "vpcity-db" {
  subnet_id      = "${aws_subnet.vpcity-a-db.id}"
  route_table_id = "${aws_route_table.vpcity-private-roads.id}"
}
resource "aws_route_table_association" "vpcity-spare" {
  subnet_id      = "${aws_subnet.vpcity-a-spare.id}"
  route_table_id = "${aws_route_table.vpcity-private-roads.id}"
}

module "cicd" {
  source = "./github/"

	github_token        = "${var.github_token}"
	github_organization = "${var.github_organization}"

}

output "payload_url" {
	value = "${module.cicd.payload_url}"
}
