module "ami" {
  source = "github.com/terraform-community-modules/tf_aws_ubuntu_ami"
  region = "${var.aws_region}"
  distribution = "trusty"
  architecture = "amd64"
  virttype = "hvm"
  storagetype = "ebs-ssd"
}
