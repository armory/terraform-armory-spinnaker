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
