# Create a new VPC to work with
resource "aws_vpc" "main" {
  cidr_block = "${lookup(var.networking, "vpc_cidr")}"
  tags {
    name       = "Main_VPC"
    managed_by = "terraform"
  }
}

# for the purpose of this exercise we will access machines from the internet
# so will have to attach an IGW to the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id            = "${aws_vpc.main.id}"
}

# Add a route to the main route table of the VPC so that machines are internet connected
resource "aws_route" "public_route" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

# create as many subnets for the app servers as we have cidr blocks defined
resource "aws_subnet" "app_subnets" {
  count             = "${length(split(",",lookup(var.networking, "private_subnet_cidr_list")))}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(split(",",lookup(var.networking, "private_subnet_cidr_list")), count.index)}"
  availability_zone = "${element(split(",",lookup(var.networking, "az_list")), count.index)}"
  map_public_ip_on_launch = true
  tags {
    Name       = "app_subnet_${element(split(",",lookup(var.networking, "az_list")), count.index)}"
    managed_by = "terraform"
  }
}

# create one subnet for the web server
resource "aws_subnet" "web_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${lookup(var.networking, "public_subnet_cidr")}"
  map_public_ip_on_launch = true
  tags {
    Name       = "web_subnet"
    managed_by = "terraform"
  }
}

# allow inbound ssh on the VPC's default security group for the purpose of this
# exercise, in a 'real world' scenario this would either be much tighter controlled
# (i.e. an office IP range)
resource "aws_security_group_rule" "allow_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # for the purpose of this demo, should really be much tighter

  security_group_id = "${aws_vpc.main.default_security_group_id}"
}

# security group for the web server, this allows inbound access on TCP port 80 to 'the world'
resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "web_sg"
    managed_by = "terraform"
  }
}

# security group for the app server, allow inbound access on TCP port 8484 from web server(s)
resource "aws_security_group" "app" {
  name   = "app"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port       = 8484
    to_port         = 8484
    protocol        = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
    tags {
      Name = "app_sg"
      managed_by = "terraform"
    }
  }
}

# create a ssh keypair to upload to all instances so we can remotely access them
# alternatively this could be skipped and we could use an existing keypair
resource "aws_key_pair" "ssh_keypair" {
  key_name = "ssh_key"
  public_key = "${file(lookup(var.keyfile, "public"))}"
  tags {
    Name = "goapp_keypair"
    managed_by = "terraform"
  }
}

# Create two app instances and provision them with chef recipes:
#   - recipe[go-app-configmanagement::default]
#   - recipe[go-app-configmanagement::go_app]
resource "aws_instance" "app" {
  count                  = 2
  ami                    = "${module.ami.ami_id}"
  key_name               = "${aws_key_pair.ssh_keypair.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${element(aws_subnet.app_subnets.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_vpc.main.default_security_group_id}","${aws_security_group.app.id}"]
  user_data              = "${format(template_file.userdata.rendered, format("app-%02d",count.index + 1))}"
  tags {
    Name       = "${format("app_%02d",count.index + 1)}"
    managed_by = "terraform"
  }

  provisioner "chef" {
    run_list               = ["go-app-configmanagement::default","go-app-configmanagement::go_app"]
    node_name              = "${format("app_%02d",count.index + 1)}"
    server_url             = "${var.chef_server_url}"
    validation_client_name = "${var.chef_validator_name}"
    validation_key         = "${file(var.chef_validator_file)}"
    connection {
      user        = "ubuntu"
      private_key = "${file(lookup(var.keyfile, "private"))}"
    }
  }
}

# Create one web instance once both app instances have been completely provisioned and
# provision it with chef recipes:
#   - recipe[go-app-configmanagement::default]
#   - recipe[go-app-configmanagement::web]
resource "aws_instance" "web" {
  depends_on             = ["aws_instance.app"]
  ami                    = "${module.ami.ami_id}"
  key_name               = "${aws_key_pair.ssh_keypair.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.web_subnet.id}"
  vpc_security_group_ids = ["${aws_vpc.main.default_security_group_id}","${aws_security_group.web.id}"]
  user_data              = "${format(template_file.userdata.rendered, "web")}"
  tags {
    Name       = "web"
    managed_by = "terraform"
  }

  provisioner "chef" {
    run_list               = ["go-app-configmanagement::default","go-app-configmanagement::nginx"]
    node_name              = "web"
    server_url             = "${var.chef_server_url}"
    validation_client_name = "${var.chef_validator_name}"
    validation_key         = "${file(var.chef_validator_file)}"
    connection {
      user = "ubuntu"
      private_key = "${file(lookup(var.keyfile, "private"))}"
    }
  }
}
