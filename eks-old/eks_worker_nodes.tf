#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

#*
resource "aws_iam_role" "aws_eks_node" {
  name_prefix = "${var.cluster_name}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#*
resource "aws_iam_instance_profile" "aws_eks_node" {
  name = "${aws_iam_role.aws_eks_node.name}"
  role = "${aws_iam_role.aws_eks_node.name}"
}

#*
resource "aws_iam_role_policy_attachment" "aws_eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.aws_eks_node.name}"
}

#*
resource "aws_iam_role_policy_attachment" "aws_eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.aws_eks_node.name}"
}

#*
resource "aws_iam_role_policy_attachment" "aws_eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.aws_eks_node.name}"
}


#*
resource "aws_security_group" "aws_eks_node" {
  name        = "${var.cluster_name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.aws_eks.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.cluster_name}-node",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

#*
resource "aws_security_group_rule" "aws_eks_node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.aws_eks_node.id}"
  source_security_group_id = "${aws_security_group.aws_eks_node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

#*
resource "aws_security_group_rule" "aws_eks_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.aws_eks_node.id}"
  source_security_group_id = "${aws_security_group.aws_eks_cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

#*
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["${var.aws_eks_ami_filter}"]
  }

  most_recent = true
  owners      = ["${var.aws_eks_ami_account_id}"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  aws_eks_node_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.aws_eks.endpoint}' --b64-cluster-ca '${aws_eks_cluster.aws_eks.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

#*
resource "aws_launch_configuration" "aws_eks" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.aws_eks_node.name}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "${var.ec2_instance_type}"
  name_prefix                 = "${var.cluster_name}"
  security_groups             = ["${aws_security_group.aws_eks_node.id}"]
  user_data_base64            = "${base64encode(local.aws_eks_node_userdata)}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "50"
  }
}

#*
resource "aws_autoscaling_group" "aws_eks" {
  launch_configuration = "${aws_launch_configuration.aws_eks.id}"
  min_size             = "${var.ec2_instances_min}" 
  max_size             = "${var.ec2_instances_max}" 
  desired_capacity     = "${var.ec2_instances_desired}"
  name                 = "${var.cluster_name}"
  vpc_zone_identifier  = "${aws_subnet.aws_eks.*.id}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  depends_on = [
    aws_eks_cluster.aws_eks,
    aws_route_table_association.aws_eks
  ]
}
