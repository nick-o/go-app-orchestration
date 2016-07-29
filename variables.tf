# variables that will be read from secrets.tfvars
variable "access_key" {}
variable "secret_key" {}
variable "chef_server_url" {}
variable "chef_validator_name" {}
variable "chef_validator_file" {}

variable "aws_region" {
  default = "eu-west-1"
}

# Map with the locations of our public and private keys to use to connect to instances
variable "keyfile" {
  type    = "map"
  default = {
    private = "~/.ssh/id_rsa"
    public  = "~/.ssh/id_rsa.pub"
  }
}

# Map with variables for networking resources
variable "networking" {
  type    = "map"
  default = {
    vpc_cidr                 = "10.0.0.0/16"
    private_subnet_cidr_list = "10.0.1.0/24,10.0.2.0/24"
    public_subnet_cidr       = "10.0.0.0/24"
    az_list                  = "eu-west-1a,eu-west-1b,eu-west-1c"
  }
}

# search criteria for the ami that we are finding via the module in modules.tf
variable "machine_image" {
  type    = "map"
  default = {
    distribution = "trusty"
    architecture = "amd64"
    virttype     = "hvm"
    storagetype  = "ebs-ssd"
  }
}
