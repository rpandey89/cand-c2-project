# Designate a cloud provider, region, and credentials
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

resource "aws_vpc" "lambda-vpc" {
    cidr_block = "10.6.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"
}

resource "aws_subnet" "lambda-subnet-public-1" {
    vpc_id = "${aws_vpc.lambda-vpc.id}"
    cidr_block = "10.6.5.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "${var.region}a"
}

resource "aws_internet_gateway" "lambda-igw" {
    vpc_id = "${aws_vpc.lambda-vpc.id}"
}

resource "aws_route_table" "lambda-public-rt" {
    vpc_id = "${aws_vpc.lambda-vpc.id}"

    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0"
        //RT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.lambda-igw.id}"
    }
}

resource "aws_route_table_association" "lambda-rt-public-subnet-1"{
    subnet_id = "${aws_subnet.lambda-subnet-public-1.id}"
    route_table_id = "${aws_route_table.lambda-public-rt.id}"
}

resource "aws_security_group" "ssh-allowed" {
    vpc_id = "${aws_vpc.lambda-vpc.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh !
        // Do not do it in the production.
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    //If you do not add this rule, you can not reach the NGIX
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "terraform_lambda" {
  filename      = "greet_lambda.py.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "greet_lambda.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("greet_lambda.py.zip"))}"
  source_code_hash = filebase64sha256("greet_lambda.py.zip")

  runtime = "python3.8"
  environment {
    variables = {
      greeting = "Good day!!"
    }
  }
  vpc_config {
    subnet_ids = ["${aws_subnet.lambda-subnet-public-1.id}"]
    security_group_ids = [aws_security_group.ssh-allowed.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.cloud_watch_lambda_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "cloud_watch_lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:Decrypt"
            ],
        "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}
