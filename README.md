# Домашнее задание к занятию "`Название занятия`" - `Фамилия и имя студента`


---

### Задание 1



1. `Создаю файл provider.tf`

```
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.98"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gvjpk4qbrvling8qq1"
  folder_id = "b1gse67sen06i8u6ri78"
  zone      = "ru-central1-a"
}

```
2. `Создаю VPC и подсети в network.tf`
```
resource "yandex_vpc_network" "main" {
  name = "netology-vpc"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

```
3. `Файл nat.tf`
```
resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    ip_address         = "192.168.10.254"
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

```

4. `Таблица маршрутов для приватной сети в route.tf`

```
resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-rt"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat.network_interface.0.ip_address
  }
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

```

5. `Виртуальные машины`
6. `Публичная`
```
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd855c73qshgd71tugqk"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

```

7. `Приватная`

```
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd855c73qshgd71tugqk"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

```
8. `Применяю конфигурацию`

```
terraform init
terraform apply
Получаю ошибку что нет подлючения к YC
*траблшутинг*
выяснил, что слетел ключ аунтификации 

echo $YC_TOKEN

# пусто, а должен быть ключ

export YC_TOKEN=$(yc iam create-token)
и все становится на свои места
```
![1](https://github.com/Foxbeerxxx/org_network_k8s/blob/main/img/img1.png)



9. `Проверяю ip адреса в веб YC`

![2](https://github.com/Foxbeerxxx/org_network_k8s/blob/main/img/img2.png)

10. `Подключаюсь на публичную ВМ по ssh`

```
ssh -i ~/.ssh/id_ed25519 ubuntu@89.169.128.243
и с нее пингую 
ping 8.8.8.8
```
![3](https://github.com/Foxbeerxxx/org_network_k8s/blob/main/img/img3.png)


11.`ProxyJump на приватную машину`

```
ssh -i ~/.ssh/id_ed25519 -J ubuntu@89.169.128.243 ubuntu@192.168.20.12

```
![4](https://github.com/Foxbeerxxx/org_network_k8s/blob/main/img/img4.png)

12.`Проверяю доступ в интернет с приватной ВМ `

```
ping -c 4 8.8.8.8
и
curl ifconfig.me

ping 8.8.8.8 прошёл — интернет работает.
curl ifconfig.me показывает внешний IP 89.169.142.65 — это NAT-инстанс.

```
![5](https://github.com/Foxbeerxxx/org_network_k8s/blob/main/img/img5.png)