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
