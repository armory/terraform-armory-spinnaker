#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

#*
resource "aws_iam_role" "aws_eks_cluster" {
  name_prefix = "${var.cluster_name}-eks"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#*
resource "aws_iam_role_policy_attachment" "aws_eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.aws_eks_cluster.name}"
}

#*
resource "aws_iam_role_policy_attachment" "aws_eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.aws_eks_cluster.name}"
}

#*
resource "aws_security_group" "aws_eks_cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.aws_eks.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}"
  }

  depends_on = [
    "aws_vpc.aws_eks"
  ]
}

#*
resource "aws_security_group_rule" "aws_eks_cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.aws_eks_cluster.id}"
  source_security_group_id = "${aws_security_group.aws_eks_node.id}"
  to_port                  = 443
  type                     = "ingress"
}

#*
resource "aws_security_group_rule" "aws_eks_cluster_ingress_workstation_https" {
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.aws_eks_cluster.id}"
  cidr_blocks       = ["${var.client_ip_range}"]
  to_port           = 443
  type              = "ingress"
}

#*
resource "aws_eks_cluster" "aws_eks" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.aws_eks_cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.aws_eks_cluster.id}"]
    subnet_ids         = "${aws_subnet.aws_eks.*.id}"
  }

  depends_on = [
    "aws_vpc.aws_eks",
    "aws_subnet.aws_eks",
    "aws_security_group.aws_eks_cluster",
    "aws_iam_role.aws_eks_cluster",
    "aws_iam_role_policy_attachment.aws_eks_cluster_AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.aws_eks_cluster_AmazonEKSServicePolicy",
  ]
}
