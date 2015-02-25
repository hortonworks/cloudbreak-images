variable owner {
    description = "Who is respomsible for the instance"
}

variable credential_dir {
    description = "Directory that containst the account and client_secret json https://www.terraform.io/docs/providers/google/index.html"
}

variable ssh_key_file {
    description = "SSH key file to be used when provisioning"
}

variable packer_image_name {
    description = "The name of the image which will be made public"
}

variable gce_zone {
    description = "GCE zone to start the cbreak deployment"
    default = "us-central1-a"
}

variable ins_type {
    description = "cbreak deployment insance size"
    default = "n1-standard-4"
}

provider "google" {
    account_file = "${var.credential_dir}/account.json"
    client_secrets_file = "${var.credential_dir}/client_secret.json"
    project = "siq-haas"
    region = "us-central1"
}

resource "google_compute_disk" "image-builder-disk" {
    name = "image-builder-disk-${var.packer_image_name}"
    type = "pd-ssd"
    zone = "${var.gce_zone}"
    size = "20"
    #image = "debian7-wheezy"
}

resource "google_compute_instance" "image-builder" {
    name = "image-builder-${var.packer_image_name}"
    machine_type = "${var.ins_type}"
    zone = "${var.gce_zone}"

    depends_on = [
        "google_compute_disk.image-builder-disk"
    ]

    disk {
        image = "${var.packer_image_name}"
    }

    disk {
        disk = "${google_compute_disk.image-builder-disk.name}"
    }

    network {
        source = "default"
    }

    provisioner "remote-exec" {

        connection {
            user = "ubuntu"
            key_file = "${var.ssh_key_file}"
        }

        script = "./create_gc_image.sh"
    }

    service_account {
        scopes = ["storage-rw"]
    }

}

output "instance" {
    value = "${google_compute_instance.image-builder.name}"
}
