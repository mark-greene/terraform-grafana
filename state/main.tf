terraform {
  required_version = ">= 0.10.0"
}

provider "aws" {
  version = "~> 1.2"

  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.tf_state_bucket}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_state" {
  name           = "${var.tf_state_table}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
