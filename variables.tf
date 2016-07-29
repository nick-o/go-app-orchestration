variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "keyfile" {
  default = "~/.ssh/id_rsa.pub"
}

variable "networking" {
  type    = "map"
  default = {
    vpc_cidr                 = "10.0.0.0/16"
    private_subnet_cidr_list = "10.0.1.0/24,10.0.2.0/24"
    public_subnet_cidr       = "10.0.0.0/24"
    az_list                  = "eu-west-1a,eu-west-1b,eu-west-1c"
  }
}

variable "machine_image" {
  type    = "map"
  default = {
    distribution = "trusty"
    architecture = "amd64"
    virttype     = "hvm"
    storagetype  = "ebs-ssd"
  }
}
