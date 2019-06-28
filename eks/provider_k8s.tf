data "aws_eks_cluster" "aws_eks" {
  name = "${aws_eks_cluster.aws_eks.name}"
}

data "aws_eks_cluster_auth" "aws_eks_auth" {
  name       = "${aws_eks_cluster.aws_eks.name}"
}

provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.aws_eks.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.aws_eks.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.aws_eks_auth.token}"
  load_config_file       = false
}


#*
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<ROLES
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: ${aws_iam_role.aws_eks_node.arn}
  username: system:node:{{EC2PrivateDNSName}}
- groups:
  - system:masters
  rolearn: ${aws_iam_role.halyard_role.arn}
  username: halyard
ROLES
    mapUsers = "${var.master_users}"
  }

  depends_on = [
    "aws_eks_cluster.aws_eks",
    "aws_autoscaling_group.aws_eks",
    "aws_route_table_association.aws_eks"
  ]
}