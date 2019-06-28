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

    type = "LoadBalancer"
  }
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

    type = "LoadBalancer"
  }
}

output "deck_endpoint" {
  value = "${kubernetes_service.spin_deck_lb.load_balancer_ingress[0].hostname}"
}

output "gate_endpoint" {
  value = "${kubernetes_service.spin_gate_lb.load_balancer_ingress[0].hostname}"
}