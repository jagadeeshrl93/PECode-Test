# AWS Lambda EC2 Remediation (Sumo Logic Alert → Lambda → EC2 Reboot + SNS)

This project implements an automated remediation workflow:
- A **Sumo Logic alert** detects slow `/api/data` responses (>3s)
- An alert is configured to trigger when **more than 5 such entries occur within 10 minutes**
- The alert triggers an AWS Lambda function (typically via a webhook bridge)
- The Lambda function:
  1) **Reboots a specified EC2 instance**
  2) **Logs** the action to CloudWatch Logs
  3) **Sends a notification** to an SNS topic

---

## Repository Structure

project/
├── lambda_function/
│ └── app.py # Lambda function code
└── terraform/
├── main.tf # Main infrastructure
├── variables.tf # Input variables
├── outputs.tf # Output values
└── versions.tf # Provider versions


---

## Part 1: Sumo Logic Query + Alert Setup

### Goal
Detect logs for `/api/data` where response time is > 3 seconds, and trigger an alert if **count > 5 within a 10-minute window**.

### Steps
1. Log into your **Sumo Logic** account.
2. Navigate to **Search**.
3. Enter your query (example: filter `/api/data` and response time > 3s).
4. Create an alert/monitor from the query:
   - Configure the evaluation window to **10 minutes**
   - Trigger condition: **count > 5**
5. Configure an action to trigger remediation:
   - Sumo alerts typically call a **Webhook (HTTP POST)**
   - A common integration is:
     **Sumo Monitor → Webhook → API Gateway → Lambda**

> Note: This repository provisions the AWS components (EC2/SNS/Lambda/IAM).  
> If API Gateway is required for your Sumo webhook integration, it can be added to Terraform.

---

## Part 2: AWS Lambda Function

### Lambda Function Behavior
The Lambda code is located in:
- `lambda_function/app.py`

It performs:
- EC2 reboot using `ec2.reboot_instances(...)`
- Logging using Python `logging`
- SNS notification using `sns.publish(...)`

### Current Configuration
The Lambda code currently uses hard-coded values:
- `INSTANCE_ID`
- `SNS_TOPIC_ARN`

This works for the coding test, but in a production setup these would be passed via **environment variables**.

---

## Part 3: Infrastructure as Code (Terraform)

Terraform provisions:
- EC2 instance (target instance)
- SNS topic (notification destination)
- Lambda function (remediation)
- IAM role/policy (permissions for logs + EC2 reboot + SNS publish)
- Lambda packaging using `archive_file`

---

## Prerequisites

- AWS account with permissions to create EC2, IAM, Lambda, SNS
- AWS CLI configured (recommended)
- Terraform installed (`>= 1.5`)

✅ Recommended AWS authentication methods:
- `aws configure` (local profile)
- environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`)
- IAM role (if running on an AWS host)

⚠️ Avoid putting AWS keys into Terraform files.

---

## Deploy Instructions

### 1) Get an AMI ID for your region
Terraform requires `ami_id`. Example to fetch a recent Amazon Linux AMI (adjust region if needed):

```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query 'Images | sort_by(@,&CreationDate) | [-1].ImageId' \
  --region us-east-2 \
  --output text
