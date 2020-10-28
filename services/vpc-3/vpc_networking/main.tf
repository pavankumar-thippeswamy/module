# Declare the data source
data "aws_availability_zones" "available" {}

# Creating VPC
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags {
    Name = "my-test-vpc"
  }
}
# Creating Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "my-test-igw"
  }
}
# Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "my-test-public-route"
  }
}
# Private Route Table

resource "aws_default_route_table" "private_route" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  tags {
    Name = "my-test-private-route"
  }
}
#Public Subnet

resource "aws_subnet" "public_subnet" {
  count = 2
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "my-test-public-subnet.${count.index + 1}"
  }
}
# Associate Public Subnet with Public Route Table

resource "aws_route_table_association" "public_subnet_assoc" {
  count = "${aws_subnet.public_subnet.count}"
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id = "${aws_subnet.public_subnet.*.id[count.index]}"
  depends_on     = ["aws_route_table.public_route", "aws_subnet.public_subnet"]

}
# Associate Private Subnet with Private Route Table

resource "aws_route_table_association" "private_subnet_assoc" {
  count = "${aws_subnet.private_subnet.count}"
  route_table_id = "${aws_default_route_table.private_route.id}"
  subnet_id = "${aws_subnet.private_subnet.*.id[count.index]}"
  depends_on     = ["aws_default_route_table.private_route", "aws_subnet.private_subnet"]
}
# Security Group

resource "aws_security_group" "test_sg" {
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
