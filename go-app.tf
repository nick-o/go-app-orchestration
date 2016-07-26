resource "aws_vpc" "main" {
  cidr_block = "${lookup(var.networking, "vpc_cidr")}"
  tags {
    name       = "Main_VPC"
    managed_by = "terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id            = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public_rt" {
  vpc_id            = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags {
    name = "public_rt"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = "${length(split(",",lookup(var.networking, "private_subnet_cidr_list")))}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(split(",",lookup(var.networking, "private_subnet_cidr_list")), count.index)}"
  availability_zone = "${element(split(",",lookup(var.networking, "az_list")), count.index)}"
  tags = {
    name       = "private_subnet_${element(split(",",lookup(var.networking, "az_list")), count.index)}"
    managed_by = "terraform"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${lookup(var.networking, "public_subnet_cidr")}"
  map_public_ip_on_launch = true
  tags {
    name = "public_subnet"
  }
}

resource "aws_route_table_association" "rt_association" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}
