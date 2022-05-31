# Creating Lambda IAM resource
resource "aws_iam_role" "lambda_iam" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "revoke_keys_role_policy" {
  name = var.lambda_iam_policy_name
  role = aws_iam_role.lambda_iam.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_file      = "../lambda_function.py"
  output_file_mode = "0666"
  output_path      = "../lambda_function.zip"
}



resource "aws_lambda_function" "test_lambda" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_iam.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.runtime
  timeout          = var.timeout
  filename         = "../lambda_function.zip"
  
  source_code_hash = filebase64sha256("../lambda_function.zip")
  environment {
    variables = {
      env            = var.environment
      bucket_name    = var.bucket_name
      file_name      = var.file_name
      resource_name  = var.resource_name
    }
  }
}

#resource "aws_lambda_function_event_invoke_config" "event-lambda" {
#  function_name = aws_lambda_function.test_lambda.function_name
#  maximum_event_age_in_seconds = 60
#  qualifier     = "$LATEST"
#  maximum_retry_attempts = var.retry //set to 0 to avoid lambda retry attempts

#  depends_on = [
#    aws_lambda_function.test_lambda
#  ]
#}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}


resource "aws_lambda_function_event_invoke_config" "lambdaexample" {
  function_name = aws_lambda_function.test_lambda.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0

}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_lambda_function.test_lambda.arn
}
