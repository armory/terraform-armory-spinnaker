### EVERY FIELD IN THIS FILE SHOULD BE UPDATED

# AWS profile for AWS account where resources will be created
provider_profile = "armory"

# AWS region where resources will be created
provider_region = "us-east-1"

# AZ where persistent volume for Spinnaker configuration will be created
ec2_halyard_az = "us-east-1a"

# Unique name for Spinnaker cluster name
cluster_name = "armory-spinnaker"

# If you want additional AWS users to be able to access your Kubernetes cluster, specify them here
master_users = <<EOF
- userarn: arn:aws:iam::012345678901:user/andrew
  username: andrew
  groups:
    - system:masters
- userarn: arn:aws:iam::795692138404:user/jason
  username: jason
  groups:
    - system:masters
EOF

# Specify an AMI for Ubuntu 18.04 in the region you are deploying to:
aws_ubuntu_ami = "ami-095192256fe1477ad"
# Other regions:
# ap-northeast-1:   ami-032cf5e284518543d
# ap-northeast-2:   ami-06d2ca2471c251818
# ap-northeast-3:   ami-0dd67b62d9f8adc65
# ap-south-1:       ami-027d1dd332103051b
# ap-southeast-1:   ami-0c2e7524d47186df7
# ap-southeast-2:   ami-035c8e816223729a6
# ca-central-1:     ami-0b08c6831ffd5ea84
# eu-central-1:     ami-05b5a98cd34853d29
# eu-north-1:       ami-1b33bb65
# eu-west-1:        ami-08b1cea5487c762b3
# eu-west-2:        ami-0ee246e709782b1be
# eu-west-3:        ami-074f4c146d4f5d466
# sa-east-1:        ami-0fcd3565c065e9238
# us-east-1:        ami-095192256fe1477ad
# us-east-2:        ami-02fd7546f0f6effb6
# us-west-1:        ami-03c9dad75296f9e90
# us-west-2:        ami-04aac3d7ea7609469

# Specify the name for an AWS SSH key (in the correct AWS account and region) that you have access to
aws_halyard_ssh_key = "justin-armory-dev"