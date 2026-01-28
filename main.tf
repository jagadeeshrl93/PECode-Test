provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

data "aws_caller_identity" "current" {}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------
# EC2 instance to reboot
# -------------------------
resource "aws_instance" "target" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = {
    Name = "${var.name_prefix}-ec2"
  }
}

# -------------------------
# SNS topic for notification
# -------------------------
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-sns-topic"
}

# -------------------------
# Package Lambda code
# -------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

# -------------------------
# IAM role for Lambda
# -------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# -------------------------
# IAM policy for Lambda
# -------------------------
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.name_prefix}-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # CloudWatch Logs
      {
        Sid    = "AllowLogging",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },

      # Reboot the specific EC2 instance
      {
        Sid    = "AllowRebootInstance",
        Effect = "Allow",
        Action = [
          "ec2:RebootInstances",
          "ec2:DescribeInstances"
        ],
        Resource = aws_instance.target.arn
      },

      # Publish to the SNS topic
      {
        Sid      = "AllowSnsPublish",
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# -------------------------
# Lambda function
# -------------------------
resource "aws_lambda_function" "remediate" {
  function_name = "${var.name_prefix}-lambda"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"
  handler = "app.lambda_handler"
  timeout = 30

  environment {
    variables = {
      INSTANCE_ID   = aws_instance.target.id
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}
