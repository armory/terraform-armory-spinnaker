## Prerequisites

You must have Terraform 0.12.x installed
You must have essentially full access to your AWS account, including creating IAM resources

## Instructions

Clone the repo, `cd` into the directory:

```bash
git clone https://github.com/armory/terraform-armory-spinnaker.git
cd terraform-armory-spinnaker/eks
```

Create an S3 bucket to store Terraform state:

* The bucket should be private
* You should have an AWS credential profile that can access the bucket

Create / update a `backend.tfvars` (based on `templates/backend.tfvars`) (all four items must be updated):

```tfvar
profile = "armory-sales"
bucket = "armory-sales-justin"
key = "terraform-armory"
region = "us-east-1"
```

Initialize the terraform backend:

```bash
terraform init -backend-config backend.tfvars
```

Create / update a `config.tfvars` (based on `templates/config.tfvars`):

```bash
provider_profile = "armory-sales"
provider_region = "us-west-2"
ec2_halyard_az = "us-west-2a"
cluster_name = "armory-spinnaker"
master_users = <<EOF
- userarn: arn:aws:iam::795692138404:user/justin
  username: justin
  groups:
    - system:masters
EOF
aws_ubuntu_ami = "ami-04aac3d7ea7609469"
aws_halyard_ssh_key = "justin-armory-dev"
```

Run Terraform Plan to Verify:

```bash
terraform plan -var-file config.tfvars
```

Run Terraform Apply to Install (this will prompt for a confirmation - type `yes`):

```bash
terraform apply -var-file config.tfvars
```
