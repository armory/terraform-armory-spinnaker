
resource "aws_iam_role" "spinnaker_managed_role" {
  name_prefix = "${var.cluster_name}-managed"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.aws_eks_node.arn}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "spinnaker_managed_poweruser" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = "${aws_iam_role.spinnaker_managed_role.name}"
}

resource "aws_iam_role_policy" "spinnaker_managed_passrole" {
  name = "PassRole"
  role = "${aws_iam_role.spinnaker_managed_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "iam:PassRole",
      "Resource": [
          "*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "spinnaker_managing_assume_role" {
  name = "AssumeLocalRole"
  role = "${aws_iam_role.aws_eks_node.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Resource": [
            "${aws_iam_role.spinnaker_managed_role.arn}"
        ],
        "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "spinnaker_managing_local_permissions" {
  name = "LocalPermissions"
  role = "${aws_iam_role.aws_eks_node.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeRegions",
            "iam:ListServerCertificates"
        ],
        "Resource": [
            "*"
        ]
    }
  ]
}
EOF
}

