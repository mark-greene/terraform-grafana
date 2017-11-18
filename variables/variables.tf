variable "bucket" {
  description = "The name of the remote state bucket"
}
variable "dynamodb_table" {
  description = "The name of the remote state lock table"
}
variable "encrypt" {
  description = "Excrypt the remote state bucket"
}
variable "application" {
  description = "The name of the application"
}
variable "environment" {
  description = "Application environment [dev,qa,staging,production]"
}
variable "region" {
  description = "Geographic location"
}
variable "profile" {
  description = "Credentials"
}
variable "key_pair" {
  description = "The name of the SSH key to use on the instance"
}
variable "iam_instance_role" {
  description = "The name of the role to use on the instance"
}
