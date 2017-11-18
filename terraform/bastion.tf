variable "instance_count" {
    description = "The number of instances to create"
    default = 1
}

variable "instance_type" {
    description = "The type of instance to start"
    default = "t2.small"
}

variable "vpc_security_group_ids" {
    type = "list"
    description = "A list of security group IDs to associate with"
    default = []
}

resource "aws_instance" "bastion" {
    count = "${var.instance_count}"

    ami                    = "${module.ami_amazon.id}"
    key_name               = "${var.key_pair}"
    subnet_id              = "${element(sort(module.public_subnet.ids), count.index)}"
    instance_type          = "${var.instance_type}"
    vpc_security_group_ids = ["${module.sg_ssh.id}", "${var.vpc_security_group_ids}"]
    iam_instance_profile   = "${var.iam_instance_role}"

    associate_public_ip_address = true

    root_block_device {
        volume_size           = 16
        delete_on_termination = true
    }

    lifecycle {
        ignore_changes = ["ami_bastion"]
    }

    tags {
        "Name"        = "${format("%s-bastion", var.name)}"
        "Cluster"     = "security"
        "Role"        = "bastion"
        "Audience"    = "public"
        "Terraform"   = "true"
        "Environment" = "${var.environment}"
    }
}

module "sg_ssh" {
    source = "../modules/network/security_group/sg_ssh"

    name   = "${var.name}"
    vpc_id = "${module.vpc.id}"

    ingress_cidr_blocks = ["0.0.0.0/0"]
    egress_security_groups = ["${module.private_sg.id}"]

    tags {
        "Cluster"     = "security"
        "Audience"    = "public"
        "Environment" = "${var.environment}"
    }
}

// User to access bastion
output "user" { value = "ec2-user" }

// Private IP address to associate with the instance in a VPC
output "private_ip" { value = "${aws_instance.bastion.private_ip}" }

// The public IP address assigned to the instance
output "public_ip"  { value = "${aws_instance.bastion.public_ip}" }

output "sg_ssh_id" { value = "${module.sg_ssh.id}" }
