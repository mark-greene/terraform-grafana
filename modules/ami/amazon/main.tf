variable "profile" {
  description = "AWS profile to use."
}

variable "region" {
  description = "AWS region to use."
}

data "aws_ami" "amazon" {
  most_recent = true
  owners = ["amazon"] # Amazon

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2017.*-x86_64-gp2"]
  }
}

resource "null_resource" "amazon" {
  triggers {
    ami_id = "${data.aws_ami.amazon.id}"
  }
  provisioner "local-exec" {
    command = "packer build -var 'aws_profile=${var.profile}' -var 'aws_region=${var.region}' -var 'aws_ami_id=${data.aws_ami.amazon.id}' ../packer/aws-linux.json"
  }
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "tag:Application"
    values = ["terraform-grafana"]
  }
  filter {
    name = "name"
    values = ["amazon-linux-*"]
  }
  depends_on = ["null_resource.amazon"]
}

// AMI id
output "id" { value = "${data.aws_ami.amazon-linux.id}" }
