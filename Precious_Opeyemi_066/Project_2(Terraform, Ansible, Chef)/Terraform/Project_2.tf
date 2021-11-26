terraform {
    required_providers{
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy ="${file("iam_role.json")}"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.iam_for_lambda.id
  policy = "${file("lambda_policy.json")}"
}

locals {
  lambda_zip_location = "lambda_function/terra.zip"
  runtime_source_file = "terra.py"
}

data "archive_file" "terra_zip" {
  type        = "zip"
  source_file = "${local.runtime_source_file}"
  output_path = "${local.lambda_zip_location}"
}

resource "aws_lambda_function" "lambda_function" {
    filename = "${local.runtime_source_file}"
    function_name = "terraform_lambda_function"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "terra.Hello"
    runtime = "python3.9"
    source_code_hash = filebase64sha256("${local.runtime_source_file}")
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.iam_for_lambda.arn
  definition = "${file("definition.json")}"
}