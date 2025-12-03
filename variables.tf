variable "region" {
description = "AWS region"
type = string
default = "us-east-1"
}


variable "vpc_cidr" {
description = "CIDR da VPC"
type = string
default = "10.0.0.0/16"
}


variable "public_subnets" {
description = "Lista de CIDRs para subnets públicas"
type = list(string)
default = ["10.0.1.0/24", "10.0.2.0/24"]
}


variable "private_subnets" {
description = "Lista de CIDRs para subnets privadas"
type = list(string)
default = ["10.0.3.0/24", "10.0.4.0/24"]
}


variable "instance_type" {
description = "Tipo das instâncias EC2"
type = string
default = "t3.xlarge"
}


variable "ami_id" {
description = "AMI ID (Linux). Ajuste para sua região."
type = string
default = "ami-0ecb62995f68bb549"
}



variable "tags" {
type = map(string)
default = {
Owner = "terraform"
}
}

variable "key_name" {
  description = "The name of the key pair to use for the instance"
  type        = string
  default     = "id_softwave"
}

