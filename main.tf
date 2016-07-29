provider aws {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

resource "template_file" "userdata" {
    template = "${file("scripts/userdata.sh")}"
}
