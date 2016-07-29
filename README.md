## go-app-orchestration

The terraform templates in this Repository will provision the infrastructure to host a Golang sample app on an arbitrary number of app nodes (the default chosen for this exercise is 2) behind a nginx reverse proxy hosted on a single node.

Once the infrastructure has been provisioned, the nodes will be bootstrapped via chef with recipes from the [go-app-configmanagement](https://github.com/nick-o/go-app-configmanagement) cookbook to configure the necessary components of the stack.


# Requirements

### Terraform
The templates in this Repository have been tested with terraform version 0.6.16 and should work with any version newer than that. Terraform can be downloaded from [here](https://www.terraform.io/downloads.html).

### AWS credentials
For these templates to work you will need an AWS account. You will need to have an IAM user with the following policy attached:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```
The user will need an access_key and a secret_key. Ideally, add these into a variable file following the layout of secrets.tfvars.example (just copy it to secrets.tfvars)

### Chef server
In order to bootstrap the instances you will need to have access to a chef server, either via a [managed chef account](https://manage.chef.io) or running your own chef server. You will need your chef server url, validation key name and validation key. Those variables need to be passed in at runtime similar to the AWS credentials above. The easiest way is to also put them in the secrets.tfvars file.

### SSH keypair
You will need a SSH keypair to connect to the AWS instances. The templates default to using ~/.ssh/id_rsa, change this in variables.tf if you would like to use a different keypair.

# Usage
Clone this repository:
```
git clone https://github.com/nick-o/go-app-orchestration.git
```

Run terraform plan to see an execution plan before you apply any changes. If you set up the secrets.tfvars file like described above, you can use this command:
```
$ terraform plan -var-file secrets.tfvars
Refreshing Terraform state prior to plan...


The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_instance.app.0
    ami:                      "" => "ami-a6a62cd5"
    availability_zone:        "" => "<computed>"
    ebs_block_device.#:       "" => "<computed>"
    ephemeral_block_device.#: "" => "<computed>"
    instance_state:           "" => "<computed>"
    instance_type:            "" => "t2.micro"
...
```

If you're happy with the proposed changes, apply them with:
```
$ terraform apply -var-file secrets.tfvars
aws_instance.web: Creation complete

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: .terraform/terraform.tfstate

Outputs:

  web_public_ip = 54.194.128.50
```

You can verify the functionality via curl:
```
$ curl 54.194.128.50
Hi there, I'm served from app-02!
$ curl 54.194.128.50
Hi there, I'm served from app-01!
$ curl 54.194.128.50
Hi there, I'm served from app-02!
$ curl 54.194.128.50
Hi there, I'm served from app-01!
```

# Considerations

### AWS credentials
AWS Credentials don't necessarily have to be provided via var-file and this method has only been chosen for convenience. If the awscli is installed and configured correctly (e.g. via `aws configure`) the credentials don't have to be passed in at all. In this case, just remove all references to the access_key and secret_key variables from the templates.

### Remote Terraform State
If awscli has been installed and configured (see above), it is possible to store the terraform state in S3 following [this documentation](https://www.terraform.io/docs/state/remote/s3.html). Running the following command would achieve remote storage of state in S3:

```
terraform remote config -backend=s3 -backend-config="bucket=terraform-remote-state-prod" -backend-config="key=go-app-orchestration/terraform.tfstate"
```

The following additional policy would have to be attached to the IAM user to enable this:
```
 {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-remote-state-prod",
                "arn:aws:s3:::terraform-remote-state-prod/*"
            ]
        }
    ]
}
```
