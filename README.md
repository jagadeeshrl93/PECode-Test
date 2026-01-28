# AWS Lambda EC2 Remediation

Terraform infrastructure that creates an EC2 instance, Lambda function, and SNS topic for automated EC2 instance rebooting.

## Structure

```
project/
├── lambda_function/
│   └── app.py              # Lambda function code
└── terraform/
    ├── main.tf             # Main infrastructure
    ├── variables.tf        # Input variables
    ├── outputs.tf          # Output values
    ├── versions.tf         # Provider versions
    └── terraform.tfvars    # Variable values
```

## Setup

1. **Configure AWS credentials** in `terraform/terraform.tfvars`:
   ```
   aws_access_key_id = "your-access-key"
   aws_secret_access_key = "your-secret-key"
   ```

2. **Initialize Terraform**:
   ```powershell
   cd terraform
   ..\terraform init
   ```

3. **Plan deployment**:
   ```powershell
   ..\terraform plan
   ```

4. **Deploy infrastructure**:
   ```powershell
   ..\terraform apply
   ```

## Components

- **EC2 Instance**: Target instance for rebooting
- **Lambda Function**: Handles reboot logic and SNS notifications
- **SNS Topic**: Sends notifications after reboot
- **IAM Role/Policy**: Permissions for Lambda to reboot EC2 and publish to SNS

## Usage

The Lambda function automatically reboots the EC2 instance and sends an SNS notification when triggered.