## go-app-orchestration

The terraform templates in this Repository will provision the infrastructure to host a Golang sample app on an arbitrary number of app nodes (the default chosen for this exercise is 2) behind a nginx reverse proxy hosted on a single node.

Once the infrastructure has been provisioned, the nodes will be bootstrapped via chef with recipes from the [go-app-configmanagement](https://github.com/nick-o/go-app-configmanagement) cookbook to configure the necessary components of the stack.


# Requirements

#### [Terraform](http://terraform.io)
The templates in this Repository have been tested with terraform
