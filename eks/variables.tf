#
# Variables Configuration
#

variable "cluster_name" {
  type    = "string"
}

variable "vpc_cidr_prefix" {
  type        = "string"
  description = "First two octets of the subnets that are going to be used by the cluster. Ex: 10.0"
}

variable "client_ip_range" {
  type        = "string"
  default = "0.0.0.0/0"
  description = "CIDR block of IP addresses allowed to connect to the EKS cluster from the outside world."
}

variable "ec2_instance_type" {
  type    = "string"
}

variable "ec2_instances_min" {
  default = 1 
}

variable "ec2_instances_max" {
  default = 1 
}

variable "ec2_instances_desired" {
  default = 1 
}

variable "aws_eks_ami_filter" {
  type        = "string"
  default     = "amazon-eks-node-1.12*"
  description = "Filter for matching AMI's to use for worker nodes. Ex: amazon-eks-node-1.11*"
}

variable "aws_eks_ami_account_id" {
  type        = "string"
  default     = "602401143452"
  description = "Amazon EKS AMI Account ID."
}

variable "master_users" {
  type        = "string"
  description = "List of ARN's of master users of the cluster."
}

variable "ec2_halyard_az" {
  type        = "string"
  description = "AZ where Halyard instance will be run"
}

variable "aws_ubuntu_ami" {
  type        = "string"
  default     = "ami-095192256fe1477ad"
  # ami-04aac3d7ea7609469 is us-west-2
  description = "AMI for Halyard instance (defaults to Ubuntu 18.04)"
}

variable "aws_halyard_ssh_key" {
  type        = "string"
  default     = null
  description = "SSH key for Halyard EC2 instance"
}

# variable "aws_ubuntu_ami_account_id" {
#   type        = "string"
#   default     = "099720109477"
#   description = "Amazon Ubuntu AMI Account ID."
# }

# variable "aws_ubuntu_ami_filter" {
#   type        = "string"
#   default     = "amazon-eks-node-1.12*"
#   description = "Filter for matching AMI's to use for worker nodes. Ex: amazon-eks-node-1.11*"
# }