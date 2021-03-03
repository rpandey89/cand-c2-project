# Define the output variable for the lambda function.
data "aws_lambda_invocation" "lambda_function_invocation" {
  function_name = aws_lambda_function.terraform_lambda.function_name
  input = <<JSON
{}
JSON
}

output "result_entry" {
  value = jsondecode(data.aws_lambda_invocation.lambda_function_invocation.result)
}