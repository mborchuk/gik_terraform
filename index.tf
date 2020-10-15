// Configure the Google Cloud provider
provider "google" {
  credentials = file("gik-shop-0bc5c4ec1b82.json")
  project     = var.project_id
  region      = var.region
}

//# Create a GCS Bucket for State file
//resource "google_storage_bucket" "state_bucket" {
//  name     = var.state_bucket_name
//  location = var.region
//}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "gik-instance-web" {
  name         = "gik-vm-${random_id.instance_id.hex}-web"
  machine_type = "e2-small"
  allow_stopping_for_update = true
  zone         = var.instance-region
  tags = ["web", "ssh", "mysql"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2004-lts"
    }
  }

  // Make sure flask is installed on all new instances for later steps
  metadata_startup_script = "sudo apt-get update && sudo apt upgrade -y; sudo apt-get install -yq unzip; sudo apt install mysql-server mysql-client -yq; sudo apt install -yq php-common php-cli php-fpm php-opcache php-gd php-mysql php-curl php-intl php-xsl php-mbstring php-zip php-bcmath php-soap; sudo mkdir -p /var/www/gik.com.ua/web; sudo apt install -yq nginx"

  metadata = {
    ssh-keys = "mykola.borchuk:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    #network = google_compute_network.gik-shop-network.name
    subnetwork = google_compute_subnetwork.gik-shop-subnetwork.id

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = google_compute_address.static-gik-web.address
    }
  }
}

# External IP address for Web Server
resource "google_compute_address" "static-gik-web" {
  name = "internal-address-gik-web"
  region = var.region
}

// A single Google Cloud Engine instance
//resource "google_compute_instance" "gik-instance-db" {
//  name         = "gik-vm-${random_id.instance_id.hex}-db"
//  machine_type = "e2-micro"
//  zone         = "europe-west3-a"
//  tags = ["db", "ssh"]
//
//  boot_disk {
//    initialize_params {
//      image = "ubuntu-os-cloud/ubuntu-minimal-1804-lts"
//    }
//  }
//
//  // Make sure flask is installed on all new instances for later steps
//  metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask"
//
//  metadata = {
//    ssh-keys = "mykola.borchuk:${file("~/.ssh/id_rsa.pub")}"
//  }
//
//  network_interface {
//    #network = google_compute_network.gik-shop-network.name
//    subnetwork = google_compute_subnetwork.gik-shop-subnetwork.id
//
//    access_config {
//      // Include this section to give the VM an external ip address
//    }
//  }
//}

output "ip-web" {
  value = google_compute_instance.gik-instance-web.network_interface.0.access_config.0.nat_ip
}

//output "ip-db" {
//  value = google_compute_instance.gik-instance-db.network_interface.0.access_config.0.nat_ip
//}

resource "google_compute_network" "gik-shop-network" {
  name = "gik-shop-network"
  auto_create_subnetworks = false
  #delete_default_routes_on_create = true
  #ipv4_range = "10.0.0.0/24"
}

resource "google_compute_subnetwork" "gik-shop-subnetwork" {
  ip_cidr_range = "10.0.0.0/24"
  name = "gik-shop-subnetwork"
  network = google_compute_network.gik-shop-network.self_link
  region = "europe-west3"
}

resource "google_compute_firewall" "gik-shop-firewall-web" {
  name    = "gik-shop-firewall-web"
  network = google_compute_network.gik-shop-network.name
  target_tags = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "gik-shop-firewall-ssh" {
  name    = "gik-shop-firewall-ssh"
  network = google_compute_network.gik-shop-network.name
  target_tags = ["ssh"]
  source_ranges = ["109.86.219.219"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "gik-shop-firewall-mysql" {
  name    = "gik-shop-firewall-mysql"
  network = google_compute_network.gik-shop-network.name
  target_tags = ["mysql"]
  source_ranges = ["109.86.219.219"]

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
}