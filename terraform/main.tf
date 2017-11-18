provider "aws" {
  version = "~> 1.2"

  region  = "${var.region}"
  profile = "${var.profile}"
}

provider "null" { version = "~> 1.0" }

terraform {
  required_version = ">= 0.10.0"

  backend "s3" {}
}
