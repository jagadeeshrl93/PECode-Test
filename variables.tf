variable "region" {
  type    = string
  default = "us-east-2" # set this to the region where your EC2+SNS should live
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "name_prefix" {
  type    = string
  default = "sumo-remediation"
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS Access Key ID"
  sensitive   = true
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS Secret Access Key"
  sensitive   = true
}
