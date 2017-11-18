variable "name" {
    description = "The prefix name for all resources"
    default = "grafana"
}

variable "private_subnet_azs" {
    type = "list"
    description = "A list of availability zones to place in the private subnets"
    default = ["us-west-1c", "us-west-1b"]
}

variable "private_subnet_cidrs" {
    type = "list"
    description = "A list of private subnet cidr block"
    default = ["172.64.1.0/24", "172.64.3.0/24"]
}

variable "public_subnet_azs" {
    type = "list"
    description = "A list of availability zones to place in the public subnets"
    default = ["us-west-1c", "us-west-1b"]
}

variable "public_subnet_cidrs" {
    type = "list"
    description = "A list of public subnet cidr block"
    default = ["172.64.0.0/24", "172.64.2.0/24"]
}

variable "vpc_cidr" {
    default = "172.64.0.0/20"
}

module "vpc" {
    source = "../modules/network/vpc"

    name                 = "${var.name}"
    cidr                 = "${var.vpc_cidr}"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags {
      Role        = "virtual private cloud"
      Cluster     = "network"
      Audience    = "public"
      Environment = "${var.environment}"
    }
}

module "igw" {
    source = "../modules/network/internet_gateway"

    name   = "${var.name}"
    vpc_id = "${module.vpc.id}"

    tags {
        Role        = "internet gateway"
        Cluster     = "network"
        Audience    = "public"
        Environment = "${var.environment}"
    }
}

module "public_subnet" {
    source = "../modules/network/public_subnet"

    name                    = "${var.name}"
    vpc_id                  = "${module.vpc.id}"
    gateway_id              = "${module.igw.id}"
    cidr_blocks             = "${var.public_subnet_cidrs}"
    availability_zones      = "${var.public_subnet_azs}"
    map_public_ip_on_launch = true

    tags {
        Role        = "public subnet"
        Cluster     = "network"
        Audience    = "public"
        Environment = "${var.environment}"
    }
}

module "private_subnet" {
    source = "../modules/network/private_subnet"

    name               = "${var.name}"
    vpc_id             = "${module.vpc.id}"
    cidr_blocks        = "${var.private_subnet_cidrs}"
    public_subnet_ids  = ["${module.public_subnet.ids}"]
    nat_gateway_count  = "${length(var.public_subnet_cidrs)}"
    availability_zones = "${var.private_subnet_azs}"

    tags {
        Role        = "private subnet"
        Cluster     = "network"
        Audience    = "private"
        Environment = "${var.environment}"
    }
}

module "public_sg" {
    source = "../modules/network/security_group/sg_custom"

    name   = "${var.name}"
    vpc_id = "${module.vpc.id}"

    tags {
        "Audience"    = "public"
        "Environment" = "${var.environment}"
    }
}

module "private_sg" {
    source = "../modules/network/security_group/sg_internal"

    name   = "${var.name}"
    vpc_id = "${module.vpc.id}"

    tags {
        "Audience"    = "private"
        "Environment" = "${var.environment}"
    }
}

resource "aws_security_group_rule" "alb_inbound" {
    type            = "ingress"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_group_id = "${module.public_sg.id}"
}

resource "aws_security_group_rule" "alb_outbound" {
    type            = "egress"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    source_security_group_id = "${module.private_sg.id}"
    security_group_id = "${module.public_sg.id}"
}

module "alb" {
  source                        = "../modules/compute/alb_https"
  alb_name                      = "${var.name}-alb"
  alb_security_groups           = ["${module.public_sg.id}","${module.private_sg.id}"]
  vpc_id                        = "${module.vpc.id}"
  subnets                       = "${module.public_subnet.ids}"
  health_check_path             = "/api/health"
  backend_port                  = 3000
  alb_protocols                 = ["HTTP"]
  region                        = "${var.region}"

  create_log_bucket             = true
  log_bucket_name               = "${var.name}-alb-logs"
  log_location_prefix           = "alb"
  force_destroy_log_bucket      = true

  tags {
    "Audience"    = "public"
    "Environment" = "${var.environment}"
  }
}

module "asg" {
  source = "../modules/compute/asg"

  lc_name = "${var.name}-lc"

  image_id        = "${module.ami_grafana.id}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${module.sg_ssh.id}", "${module.private_sg.id}"]
  target_group_arns  = ["${module.alb.target_group_arn}"]
  key_name = "${var.key_pair}"
  iam_instance_profile = "${var.iam_instance_role}"

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "50"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "${var.name}-asg"
  vpc_zone_identifier       = ["${module.private_subnet.ids}"]
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.name}-server"
      propagate_at_launch = true
    },
  ]
}

// A list of private subnet IDs
output "private_subnet_ids" { value = "${module.private_subnet.ids}" }

// A list of public subnet IDs
output "public_subnet_ids" { value = "${module.public_subnet.ids}" }

// The ID of the VPC
output "vpc_id" { value = "${module.vpc.id}" }
