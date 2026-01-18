terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.177.0"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "10"
  image_id = "fd878mk5p0ao0vmo0ld8"
}

resource "yandex_compute_disk" "boot-disk-2" {
  name     = "boot-disk-2"
  type     = "network-hdd"
  zone     = "ru-central1-b"
  size     = "10"
  image_id = "fd878mk5p0ao0vmo0ld8"
}

resource "yandex_compute_disk" "boot-disk-bastion" {
  name = "disk-vm-bastion"
  type = "network-hdd"
  zone = "ru-central1-b"
  size = "10"
  image_id = "fd878mk5p0ao0vmo0ld8"
}

resource "yandex_compute_disk" "boot-disk-zabbix" {
  name = "disk-vm-zabbix"
  type = "network-hdd"
  zone = "ru-central1-b"
  size = "10"
  image_id = "fd878mk5p0ao0vmo0ld8"
}

resource "yandex_compute_disk" "boot-disk-elastic" {
  name = "disk-vm-elastic"
  type = "network-hdd"
  zone = "ru-central1-b"
  size = "10"
  image_id = "fd878mk5p0ao0vmo0ld8"
}

resource "yandex_compute_disk" "boot-disk-kibana" {
  name = "disk-vm-kibana"
  type = "network-hdd"
  zone = "ru-central1-b"
  size = "10"
  image_id = "fd878mk5p0ao0vmo0ld8"
}

resource "yandex_compute_instance" "bastion" {
  name = "bastion"
  hostname = "bastion"
  zone = "ru-central1-b" 
  platform_id = "standard-v3" 

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.boot-disk-bastion.id}"
    }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
    metadata = {
    user-data = "${file("/home/osboxes/diplomterraform/meta.txt")}"
    serial-port-enable = 1
  }

  scheduling_policy {  
  preemptible = true
  }
}

resource "yandex_compute_instance" "kpavlov-1" {
  name = "kpavlov-1"
  hostname = "kpavlov-1"
  zone = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }
  scheduling_policy { 
   preemptible = true 
  }
   
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web.id]
    }

  metadata = {
  user-data = "${file("/home/osboxes/diplomterraform/meta.txt")}"
  serial-port-enable = 1
}
}

resource "yandex_compute_instance" "kpavlov-2" {
  name = "kpavlov-2"
  hostname = "kpavlov-2"
  zone = "ru-central1-b"
  platform_id = "standard-v3" 

 resources {
 cores  = 2
 memory = 2
 core_fraction = 20
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-2.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web.id]
  }
  

  metadata = {
  user-data = "${file("/home/osboxes/diplomterraform/meta.txt")}"
  serial-port-enable = 1
  }
  scheduling_policy { 
  preemptible = true 
  }
  }


resource "yandex_compute_instance" "zabbix" {
  name = "zabbix"
  hostname = "zabbix"
  zone = "ru-central1-b"
  allow_stopping_for_update = true
  platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.boot-disk-zabbix.id}"
    }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.zabbix.id]
  }

  metadata = {
  user-data = "${file("/home/osboxes/diplomterraform/meta.txt")}"
  serial-port-enable = 1
  }

  scheduling_policy {  
    preemptible = true
  }
}

resource "yandex_compute_instance" "elastic" {
  name = "elastic"
  hostname = "elastic"
  zone = "ru-central1-b"
  allow_stopping_for_update = true
  platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.boot-disk-elastic.id}"
    }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat = false
    security_group_ids = [yandex_vpc_security_group.LAN.id]
  }

  metadata = {
  user-data = "${file("/home/osboxes/diplomterraform/meta.txt")}"
  serial-port-enable = 1
  }

  scheduling_policy {  
    preemptible = true
  }
}

resource "yandex_compute_instance" "kibana" {
  name = "kibana"
  hostname = "kibana"
  zone = "ru-central1-b"
  allow_stopping_for_update = true
  platform_id = "standard-v3"

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    disk_id = "${yandex_compute_disk.boot-disk-kibana.id}"
    }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.kibana.id]
  }

  metadata = {
  user-data = "${file("/home/osboxes/diplomterraform/meta.txt")}"
  serial-port-enable = 1
  }

  scheduling_policy {  
    preemptible = true

  }
}

resource "local_file" "inventory" {
  content  = <<-XYZ
  [bastion]
  ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}
  [webservers]
  ${yandex_compute_instance.kpavlov-1.network_interface.0.ip_address}
  ${yandex_compute_instance.kpavlov-2.network_interface.0.ip_address}
  [services]
  ${yandex_compute_instance.zabbix.network_interface.0.ip_address}
  ${yandex_compute_instance.elastic.network_interface.0.ip_address}
  ${yandex_compute_instance.kibana.network_interface.0.ip_address}
  XYZ
  filename = "/home/osboxes/diplomterraform/hosts.ini"
}

#----------create shapshot schedule (every day at 1:00 am)
resource "yandex_compute_snapshot_schedule" "kpavlov" {
  name = "kpavlov-snap"

  schedule_policy {
    expression = "0 1 ? * *"
  }

  snapshot_count = 1

  retention_period = "168h"

  snapshot_spec {
    description = "kpavlov-spec"
  }

  disk_ids = [
    "${yandex_compute_instance.bastion.boot_disk.0.disk_id}", 
    "${yandex_compute_instance.kpavlov-1.boot_disk.0.disk_id}",
    "${yandex_compute_instance.kpavlov-2.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elastic.boot_disk.0.disk_id}",
    "${yandex_compute_instance.kibana.boot_disk.0.disk_id}",
    "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}",
    ]
}



