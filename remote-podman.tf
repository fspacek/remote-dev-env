resource "digitalocean_droplet" "remote-podman" {
  image = "ubuntu-20-04-x64"
  name = "remote-podman"
  region = "fra1"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  provisioner "remote-exec" {
    inline = [
      "echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list",
      "curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key | sudo apt-key add -",
      "sudo apt update",
      "sudo apt install python3 -y"]

    connection {
      host = self.ipv4_address
      type = "ssh"
      user = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' add-devops-user.yml"
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u devops -i '${self.ipv4_address},' --private-key ${var.devops_key} install-podman.yml"
  }
}

resource "digitalocean_record" "dev" {
  domain = var.domain
  type = "A"
  name = "@"
  value = digitalocean_droplet.remote-podman.ipv4_address
}