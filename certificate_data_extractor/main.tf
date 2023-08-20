provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_iam_role" "lambda_acm_read_role" {
  name = "LambdaACMReadRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_acm_read_policy" {
  name = "LambdaACMReadPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "acm:ListTagsForCertificate"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_acm_policy_attachment" {
  name       = "LambdaACMPolicyAttachment"
  roles      = [aws_iam_role.lambda_acm_read_role.name]
  policy_arn = aws_iam_policy.lambda_acm_read_policy.arn
}

data "archive_file" "lambda_acm_zip" {
  type        = "zip"
  source_file = "certificate_data_extractor.py"
  output_path = "certificate_data_extractor.zip"
}

resource "aws_lambda_function" "certificate_data_extractor" {
  function_name    = "CertificateDataExtractor"
  role             = aws_iam_role.lambda_acm_read_role.arn
  handler          = "certificate_data_extractor.lambda_handler"
  runtime          = "python3.11"
  filename         = "certificate_data_extractor.zip"
}

resource "aws_cloudwatch_event_rule" "certificate_data_extractor_daily_run" {
    name = "certificate-data-extractor-daily-run"
    description = "Triggers the certificate-data-extractor lambda every day at 9:00 AM"
    schedule_expression = "cron(0 9 * * ? *)"
}

resource "aws_cloudwatch_event_target" "certificate_data_collector_lambda_target" {
    rule = aws_cloudwatch_event_rule.certificate_data_extractor_daily_run.name
    target_id = "certificate_data_extractor"
    arn = aws_lambda_function.certificate_data_extractor.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_certificate_data_extractor" {
    statement_id = "AllowExecutionFromCloudWatchToCertificateDataExtractor"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.certificate_data_extractor.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.certificate_data_extractor_daily_run.arn
}