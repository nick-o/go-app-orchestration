# set up the tf_aws_ubuntu_ami module that allows us to dynamically search
# for ami ids based on below search criteria. that helps in situations where
# AWS decide to retire an ami or when we want to quickly switch regions
module "ami" {
  source       = "github.com/terraform-community-modules/tf_aws_ubuntu_ami"
  region       = "${var.aws_region}"
  distribution = "${lookup(var.machine_image, "distribution")}"
  architecture = "${lookup(var.machine_image, "architecture")}"
  virttype     = "${lookup(var.machine_image, "virttype")}"
  storagetype  = "${lookup(var.machine_image, "storagetype")}"
}
