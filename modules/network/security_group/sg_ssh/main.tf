/**
 * This modules create an [AWS Security Group](https://www.terraform.io/docs/providers/aws/d/security_group.html) for SSH
 *
 * Ports:
 *
 * - TCP 22 (SSH)
 */

variable "name" {
    description = "The security group name, will follow the format [name]-sg-ssh-[03d], e.g. moltin-sg-ssh-001"
}

variable "tags" {
    default = {}
    description = "A map of tags to assign to the resource, `Name` and `Terraform` will be added by default"
}

variable "ingress_cidr_blocks" {
    type = "list"
    default = ["0.0.0.0/0"]
    description = "A list of ingress CIDR blocks"
}

variable "egress_security_groups" {
    type = "list"
    description = "The security groups to allow access"
}

variable "vpc_id" {
    description = "The id of the VPC that the desired subnet belongs to"
}

resource "aws_security_group" "mod" {
    name        = "${var.name}-sg-ssh"
    vpc_id      = "${var.vpc_id}"
    description = "SSH default access ports"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = "${var.ingress_cidr_blocks}"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        security_groups = ["${var.egress_security_groups}"]
    }

    tags = "${merge(var.tags, map("Name", format("%s-sg-ssh", var.name)), map("Terraform", "true"))}"
}

// The id of the specific security group to retrieve
output "id" { value = "${aws_security_group.mod.id}" }
