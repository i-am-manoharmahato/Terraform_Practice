# Specify the provider and access details
provider "aws" {
  region = "ap-southeast-2"
}

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "certificateScanner.py"
  output_path = "certificateScanner.zip"
}

data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "terraform_function_role" {
  name               = "terraform_function_role"
  assume_role_policy = "${data.aws_iam_policy_document.AWSLambdaTrustPolicy.json}"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = "${aws_iam_role.terraform_function_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "certificateScanner" {
  filename         = "${data.archive_file.zip.output_path}"
  function_name    = "certificateScanner"
  handler          = "certificateScanner.handler"
  role             = "${aws_iam_role.terraform_function_role.arn}"
  runtime          = "python3.11"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"
}