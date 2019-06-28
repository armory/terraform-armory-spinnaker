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

resource "kubernetes_namespace" "spinnaker" {
  metadata {
    annotations = {
      name = "spinnaker"
    }

    name = "spinnaker"
  }

  depends_on = [
    "aws_eks_cluster.aws_eks",
    "aws_autoscaling_group.aws_eks",
    "aws_route_table_association.aws_eks"
  ]
}

resource "kubernetes_service" "spin_deck_lb" {
  metadata {
    name = "spin-deck-lb"
    namespace = "spinnaker"
  }
  spec {
    selector = {
      app = "spin"
      cluster = "spin-deck"
    }
    port {
      port = 80
      target_port = 9000
    }

    load_balancer_source_ranges = ["${var.client_ip_range}"]

    type = "LoadBalancer"
  }

  depends_on = [
    "aws_eks_cluster.aws_eks",
    "aws_autoscaling_group.aws_eks",
    "kubernetes_namespace.spinnaker",
    "aws_route_table_association.aws_eks"
  ]
}

resource "kubernetes_service" "spin_gate_lb" {
  metadata {
    name = "spin-gate-lb"
    namespace = "spinnaker"
  }
  spec {
    selector = {
      app = "spin"
      cluster = "spin-gate"
    }
    port {
      port = 80
      target_port = 8084
    }

    load_balancer_source_ranges = ["${var.client_ip_range}"]

    type = "LoadBalancer"
  }

  depends_on = [
    "aws_eks_cluster.aws_eks",
    "aws_autoscaling_group.aws_eks",
    "kubernetes_namespace.spinnaker",
    "aws_route_table_association.aws_eks"
  ]
}

output "deck_endpoint" {
  value = "${kubernetes_service.spin_deck_lb.load_balancer_ingress[0].hostname}"
}

output "gate_endpoint" {
  value = "${kubernetes_service.spin_gate_lb.load_balancer_ingress[0].hostname}"
}