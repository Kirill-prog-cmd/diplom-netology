
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}


resource "yandex_vpc_subnet" "subnet-1" {
  name = "subnet1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.0.1.0/28"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "subnet-2" {
  name = "subnet-2"
  zone = "ru-central1-b"
  network_id = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.0.2.0/28"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "natgateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name = "route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_security_group" "bastion" {
  name = "bastion"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description = "Allow 0.0.0.0/0"
    protocol = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 22
  }
  egress {
    description = "Permit ANY"
    protocol = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "kibana" {
  name = "kibana"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description = "Allow 0.0.0.0/0"
    protocol = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 5601
  }
  ingress {
    description = "Allow ICMP"
    protocol = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    description = "Permit ANY"
    protocol = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "zabbix" {
  name = "zabbix"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description = "Allow 0.0.0.0/0"
    protocol = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 10051
  }
  ingress {
    description = "Allow 0.0.0.0/0"
    protocol = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 80
  }
  ingress {
    description = "Allow ICMP"
    protocol = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    description = "Permit ANY"
    protocol = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "LAN" {
  name = "LAN"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description = "Allow 10.0.0.0/8"
    protocol = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    description = "Permit ANY"
    protocol = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web" {
  name       = "web"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description = "Allow HTTPS"
    protocol = "TCP"
    port = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP"
    protocol = "TCP"
    port = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "public_lb" {
  name       = "public-lb"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    description = "Health checks"
    protocol = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    description = "Allow TCP"
    protocol = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 80
  }

  ingress {
    description = "Allow ICMP"
    protocol = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permit ANY"
    protocol = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#----------create target group
resource "yandex_alb_target_group" "target_group" {
  name           = "target-group"
  target {
    subnet_id    = yandex_vpc_subnet.subnet-1.id
    ip_address   = yandex_compute_instance.kpavlov-1.network_interface.0.ip_address
  }

  target {
    subnet_id    = yandex_vpc_subnet.subnet-2.id
    ip_address   = yandex_compute_instance.kpavlov-2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "backend_group" {
  name = "backend-group"
  http_backend {
    name = "backend"
    weight = 1
    port = 80
    target_group_ids = [yandex_alb_target_group.target_group.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout  = "10s"
      interval = "2s"
      healthy_threshold = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "http_router" {
  name = "http-router"
}

resource "yandex_alb_virtual_host" "virtual-host" {
  name = "virtual-host"
  http_router_id = yandex_alb_http_router.http_router.id
  route {
    name = "network-route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.backend_group.id
        timeout  = "5s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "network_lb" {
  name        = "networklb"
  network_id  = yandex_vpc_network.network-1.id
  security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.public_lb.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id
    }
  }

  listener {
    name = "network-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http_router.id
      }
    }
  }
}
