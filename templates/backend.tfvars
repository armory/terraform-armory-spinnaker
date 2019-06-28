# AWS profile used to access S3 for Terraform backend
profile = "armory"

# This S3 bucket should already exist, and should be accessible from the AWS profile
bucket = "terraform"

# This is the path/file within the bucket to store TF state
key = "terraform-armory"

# This is the region that the TF bucket exists in
region = "us-east-1"