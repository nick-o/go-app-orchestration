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

resource "aws_route" "public_route" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_subnet" "app_subnets" {
  count             = "${length(split(",",lookup(var.networking, "private_subnet_cidr_list")))}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(split(",",lookup(var.networking, "private_subnet_cidr_list")), count.index)}"
  availability_zone = "${element(split(",",lookup(var.networking, "az_list")), count.index)}"
  map_public_ip_on_launch = true
  tags {
    name       = "app_subnet_${element(split(",",lookup(var.networking, "az_list")), count.index)}"
    managed_by = "terraform"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${lookup(var.networking, "public_subnet_cidr")}"
  map_public_ip_on_launch = true
  tags {
    name = "web_subnet"
  }
}

resource "aws_security_group_rule" "allow_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # for the purpose of this demo, should really be much tighter

  security_group_id = "${aws_vpc.main.default_security_group_id}"
}

resource "aws_security_group" "web" {
  name = "web"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name = "app"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 8484
    to_port = 8484
    protocol = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }
}

resource "aws_key_pair" "ssh_keypair" {
  key_name = "ssh_key"
  public_key = "${file(var.keyfile)}"
}

resource "aws_instance" "web" {
  ami                    = "${module.ami.ami_id}"
  key_name               = "${aws_key_pair.ssh_keypair.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.web_subnet.id}"
  vpc_security_group_ids = ["${aws_vpc.main.default_security_group_id}","${aws_security_group.web.id}"]
  tags {
    name = "web"
    managed_by = "terraform"
  }
}

resource "aws_instance" "app" {
  count                  = 2
  ami                    = "${module.ami.ami_id}"
  key_name               = "${aws_key_pair.ssh_keypair.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${element(aws_subnet.app_subnets.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_vpc.main.default_security_group_id}","${aws_security_group.app.id}"]
  tags {
    name = "${format("app_%02d",count.index + 1)}"
    managed_by = "terraform"
  }
}
