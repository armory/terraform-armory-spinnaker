resource "aws_ebs_volume" "halyard_config" {
  availability_zone = "${var.ec2_halyard_az}"
  size              = 2

  tags = {
    Name = "Halyard"
  }
}

resource "aws_s3_bucket" "armory_spinnaker_bucket" {
  tags = {
    Name = "Armory Spinnaker"
  }
}


#*
resource "aws_security_group" "aws_ec2_halyard" {
  name        = "${var.cluster_name}-halyard"
  description = "Security group for halyard"
  vpc_id      = "${aws_vpc.aws_eks.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-halyard"
  }
}

#*
resource "aws_security_group_rule" "aws_ec2_halyard_ssh" {
  cidr_blocks       = ["${var.eks_client}"]
  description       = "Allow workstation to SSH into Halyard"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.aws_ec2_halyard.id}"
  to_port           = 22
  type              = "ingress"
}

data "aws_iam_policy_document" "instance_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#*
resource "aws_iam_role" "halyard_role" {
  name = "${var.cluster_name}-halyard-role"

  assume_role_policy = "${data.aws_iam_policy_document.instance_role_assume_policy.json}"
}

resource "aws_iam_instance_profile" "halyard_role" {
  name = "${var.cluster_name}-halyard-profile"
  role = "${aws_iam_role.halyard_role.name}"

}

resource "aws_iam_role_policy" "halyard_s3_bucket_policy" {
  name = "${var.cluster_name}-halyard-s3"
  role = "${aws_iam_role.halyard_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.armory_spinnaker_bucket.id}",
                "arn:aws:s3:::${aws_s3_bucket.armory_spinnaker_bucket.id}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "halyard_eks_policy" {
  name = "${var.cluster_name}-halyard-eks"
  role = "${aws_iam_role.halyard_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:ListUpdates",
                "eks:DescribeUpdate",
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_instance" "halyard_ec2" {
  ami                           = "${var.aws_ubuntu_ami}"
  instance_type                 = "t3.medium"

  subnet_id                     = "${aws_subnet.aws_halyard.id}"
  vpc_security_group_ids        = ["${aws_security_group.aws_ec2_halyard.id}"]
  iam_instance_profile          = "${aws_iam_instance_profile.halyard_role.name}"
  associate_public_ip_address   = true

  tags = {
    Name = "${var.cluster_name}-halyard"
  }

}

# data "aws_ami" "halyard_ami" {
#   filter {
#     name   = "name"
#     values = ["${var.aws_eks_ami_filter}"]
#   }

#   most_recent = true
#   owners      = ["${var.aws_eks_ami_account_id}"] # Amazon EKS AMI Account ID
# }