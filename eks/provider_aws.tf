#
# Provider Configuration
#

provider "aws" {
  version = "~> 2.7"
  region = "${var.provider_region}"
  profile = "${var.provider_profile}"
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

# data "aws_eks_cluster" "aws_eks" {
#   name = "${aws_eks_cluster.aws_eks.name}"
# }

# data "aws_eks_cluster_auth" "aws_eks_auth" {
#   name       = "${aws_eks_cluster.aws_eks.name}"
# }

# provider "kubernetes" {
#   host                   = "${data.aws_eks_cluster.aws_eks.endpoint}"
#   cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.aws_eks.certificate_authority.0.data)}"
#   token                  = "${data.aws_eks_cluster_auth.aws_eks_auth.token}"
#   load_config_file       = false
# }
