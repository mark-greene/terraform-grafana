
module "ami_amazon" {
    source = "../modules/ami/amazon"

    profile = "${var.profile}"
    region = "${var.region}"
}

module "ami_grafana" {
    source = "../modules/ami/grafana"

    ami_id = "${module.ami_amazon.id}"
    profile = "${var.profile}"
    region = "${var.region}"
}

output "amazon_id" {
  value = "${module.ami_amazon.id}"
}

output "grafana_id" {
  value = "${module.ami_grafana.id}"
}
