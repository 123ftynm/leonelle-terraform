variable "ami_id" {
  type    = string
  default = "ami-0a4f913c1801e18a2"
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "region_name" {
  type    = string
  default = "ap-southeast-2"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/20"
}

variable "az1" {
  type    = string
  default = "ap-southeast-2a"
}
variable "az2" {
  type    = string
  default = "ap-southeast-2b"
}

variable "kms_key" {
  type    = string
  default = "d8eba667-a661-467e-aa70-12b750d7d882"
}
variable "sg_id" {
  type    = string
  default = "sg-05361575d086dc6d5"
}



