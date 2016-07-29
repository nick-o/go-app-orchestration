# output the public IP of the web node that has been provisioned
output "web_public_ip" {
  value = "${aws_instance.web.public_ip}"
}
