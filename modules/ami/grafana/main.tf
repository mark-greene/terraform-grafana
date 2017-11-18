variable "ami_id" {
  description = "The AMI to add Grafana server"
}

variable "profile" {
  description = "AWS profile to use."
}

variable "region" {
  description = "AWS region to use."
}

resource "null_resource" "grafana" {
  triggers {
    ami_id = "${var.ami_id}"
  }
  provisioner "local-exec" {
    command = "packer build -var 'aws_profile=${var.profile}' -var 'aws_region=${var.region}' -var 'aws_ami_id=${var.ami_id}' ../packer/aws-grafana.json"
  }
}

data "aws_ami" "grafana" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "tag:Application"
    values = ["terraform-grafana"]
  }
  filter {
    name = "name"
    values = ["grafana-*"]
  }

  depends_on = ["null_resource.grafana"]
}

// AMI id
output "id" { value = "${data.aws_ami.grafana.id}" }
