variable cidr_block {
  default = "10.0.0.0/16"
}

resource "aws_vpc" "vpcity" {
  cidr_block       = "${var.cidr_block}"
  instance_tenancy = "default"

  tags = {
    Name = "vpcity"
  }
}

resource "aws_subnet" "vpcity-a-public" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region_name}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-public"
  }
}

resource "aws_subnet" "vpcity-a-private" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region_name}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-private"
  }
}

resource "aws_subnet" "vpcity-a-db" {
  cidr_block        = "10.0.3.0/25"
  availability_zone = "${var.aws_region_name}a"
  vpc_id            = "${aws_vpc.vpcity.id}"

  tags = {
    Name = "vpcity-a-db"
  }
}

resource "aws_subnet" "vpcity-a-spare" {
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region_name}a"
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
  vpc = true

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
    cidr_block     = "0.0.0.0/0"
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

# Security groups
resource "aws_security_group" "private-http" {
  name        = "private-http"
  description = "Allow private HTTP"
  vpc_id      = "${aws_vpc.vpcity.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-http"
  }
}

resource "aws_security_group" "public-http" {
  name        = "public-http"
  description = "Allow public HTTP"
  vpc_id      = "${aws_vpc.vpcity.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-http"
  }
}
