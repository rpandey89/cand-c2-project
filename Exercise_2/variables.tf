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

variable "lambda_function_name" {
    type = string
    default = "terraform_lambda_exercise"
}