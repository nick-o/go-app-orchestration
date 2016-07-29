# set up the AWS provider with the credentials provided in secrets.tfvars
provider aws {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

# read the template file from disk that we use as userdata script
resource "template_file" "userdata" {
    template = "${file("scripts/userdata.sh")}"
}
