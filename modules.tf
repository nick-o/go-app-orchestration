module "ami" {
  source       = "github.com/terraform-community-modules/tf_aws_ubuntu_ami"
  region       = "${var.aws_region}"
  distribution = "${lookup(var.machine_image, "distribution")}"
  architecture = "${lookup(var.machine_image, "architecture")}"
  virttype     = "${lookup(var.machine_image, "virttype")}"
  storagetype  = "${lookup(var.machine_image, "storagetype")}"
}
