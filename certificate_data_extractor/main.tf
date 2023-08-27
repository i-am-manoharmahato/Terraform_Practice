locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "lambda_assume_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name = "${var.app_name}-lambda-iam-policy"
  description = "IAM policy used by ${var.app_name} lambda"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role" "lambda" {
  name = "${var.app_name}-lambda-iam-role"
  description = "IAM role used by ${var.app_name} lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "archive_file" "extract_certificate_details" {
  type = "zip"
  source_file = "lambda_source/extract_certificate_details.py"
  output_path = "${var.app_name}-extract-certificate-details.zip"
}

resource "aws_lambda_function" "extract_certificate_details" {
  function_name = "${var.app_name}-extract-certificate-details"
  description = "Lambda used by ${var.app_name} to extract certificate data"
  role = aws_iam_role.lambda.arn
  handler = "extract_certificate_details.lambda_handler"
  runtime = "python3.11"
  timeout = 10
  filename = "${var.app_name}-extract-certificate-details.zip"
  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

data "archive_file" "lambda_layer" {
  type = "zip"
  source_dir = "lambda_layer/"
  output_path = "${var.app_name}-lambda-layer.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "${var.app_name}-lambda_layer"
  description = "Lambda layer used by ${var.app_name} lambda"
  filename = "${var.app_name}-lambda-layer.zip"
  source_code_hash = data.archive_file.lambda_layer.output_base64sha256
  compatible_runtimes = ["python3.11"]
}