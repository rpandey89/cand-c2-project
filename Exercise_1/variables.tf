variable "region" {
    type = string
    default = "us-west-1"
}

variable "access_key" {
    description = "aws access key"
    type = string
    default = ""
}

variable "secret_key" {
    description = "aws secret key"
    type = string
    default = ""
}

variable "subnet_id" {
    description = "Subnet id in an existing vpc"
    type = string
    default = ""
}