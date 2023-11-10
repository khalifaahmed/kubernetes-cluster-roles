# EC2 Instances

# resource "aws_route53_zone" "primary" {
#   name = "mosaabradi.com"
# }

# output "name_server_of_the_hosted_zone_man" {
#   value = aws_route53_zone.primary.name_servers
# }

# these nameservers will route traffic to mosaabradi.com --> but to do so --
# --> the alibaba must give them the permission to route traffic to mosaabradi.com

# resource "aws_route53_record" "www" {
#   zone_id = "${aws_route53_zone.primary.zone_id}"
#   name    = "example.com"
#   type    = "A"

#   alias {
#     name                   = "${aws_elb.main.dns_name}"
#     zone_id                = "${aws_elb.main.zone_id}"
#     evaluate_target_health = true
#   }
# }


# resource "aws_globalaccelerator_accelerator" "ga1" {
#   name            = "Example"
#   ip_address_type = "IPV4"
#   enabled         = true

# }

# resource "aws_globalaccelerator_listener" "ga1_listener" {
#   accelerator_arn = "${aws_globalaccelerator_accelerator.ga1.id}"
#   client_affinity = "SOURCE_IP"
#   protocol        = "TCP"

#   port_range {
#     from_port = 80
#     to_port   = 80
#   }
# }

# resource "aws_globalaccelerator_endpoint_group" "example" {
#   listener_arn = "${aws_globalaccelerator_listener.ga1_listener.id}"

#   endpoint_configuration {
#     endpoint_id = "${aws_eip.extra_public_ip[0].id}"
#     weight      = 100
#   }
# }


# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "${data.aws_region.current_region.name}-terraform-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename        = "${aws_key_pair.key_pair.key_name}.pem"
  content         = tls_private_key.key_pair.private_key_pem
  file_permission = "0400"

  provisioner "local-exec" {
    command = "ssh-add -k ${path.module}/${aws_key_pair.key_pair.key_name}.pem"
  }
}

resource "aws_instance" "master" {
  count         = 0
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t3.medium"
  # user_data                   = file("${path.module}/kubernetes/user_data.sh") 
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["ssh"].id, aws_security_group.grad_proj_sg["http_https"].id, aws_security_group.grad_proj_sg["public"].id] #vpc_security_group_ids      = [ aws_security_group.http-only.id, aws_security_group.ssh-only.id ]
  root_block_device {
    volume_size = 10
  }
  credit_specification {
    cpu_credits = "standard" #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }
  tags = {
    "Name" = "master-node"
  }

  #   provisioner "local-exec" {
  #     command = <<-EOT2
  # #!/bin/bash

  # sudo swapoff -a
  # cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
  # overlay
  # br_netfilter
  # EOF

  # sudo modprobe overlay
  # sudo modprobe br_netfilter

  # # sysctl params required by setup, params persist across reboots
  # cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
  # net.bridge.bridge-nf-call-iptables  = 1
  # net.bridge.bridge-nf-call-ip6tables = 1
  # net.ipv4.ip_forward                 = 1
  # EOF

  # # Apply sysctl params without reboot
  # sudo sysctl --system

  # sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

  # sudo apt-get update
  # sudo apt-get install -y containerd

  # sudo mkdir -p /etc/containerd
  # containerd config default | sudo tee /etc/containerd/config.toml

  # sudo systemctl restart containerd

  #     EOT2
  #   }
  #   depends_on = [aws_instance.master]

}


resource "aws_instance" "kube_cluster" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu_ami.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["ssh"].id, aws_security_group.grad_proj_sg["http_https"].id, aws_security_group.grad_proj_sg["public"].id] #vpc_security_group_ids      = [ aws_security_group.http-only.id, aws_security_group.ssh-only.id ]
  root_block_device {
    volume_size = 10
  }
  credit_specification {
    cpu_credits = "standard" #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }
  tags = {
    "Name" = "master-node"
  }
  # provisioner "local-exec" {
  #   command = "export master_public_ip=${aws_instance.kube_cluster[0].public_ip} master_private_ip=${aws_instance.kube_cluster[0].private_ip} worker1_public_ip=${aws_instance.kube_cluster[1].private_ip} worker1_private_ip=${aws_instance.kube_cluster[1].private_ip}; envsubst '$master_public_ip,$master_private_ip,$worker1_public_ip,$worker1_private_ip' < ./kubernetes/master-node-vars > ./kubernetes/master-node.yaml; sleep 125; ansible-playbook --inventory ${aws_instance.kube_cluster[0].public_ip},${aws_instance.kube_cluster[1].public_ip} --user ubuntu  ./kubernetes/master-node.yaml"
  # }
}

resource "null_resource" "kube_cluster" {
  provisioner "local-exec" {
    command = "export master_public_ip=${aws_instance.kube_cluster[0].public_ip} master_private_ip=${aws_instance.kube_cluster[0].private_ip} worker1_public_ip=${aws_instance.kube_cluster[1].public_ip} worker1_private_ip=${aws_instance.kube_cluster[1].private_ip}; envsubst '$master_public_ip,$master_private_ip,$worker1_public_ip,$worker1_private_ip' < ./kubernetes/master-node-vars > ./kubernetes/master-node.yaml; sleep 125; ansible-playbook --inventory ${aws_instance.kube_cluster[0].public_ip},${aws_instance.kube_cluster[1].public_ip} --user ubuntu  ./kubernetes/master-node.yaml"
  }
  depends_on = [aws_instance.kube_cluster[0],
  aws_instance.kube_cluster[1]]
}

# resource "null_resource" "kubespray" {
#   provisioner "local-exec" {
#     command = "ansible-playbook --inventory ${aws_instance.kube_cluster[0].public_ip},${aws_instance.kube_cluster[1].public_ip} --user ubuntu  ./kubernetes/master-node.yaml"
#   }
#   depends_on = [aws_instance.kube_cluster[0], aws_instance.kube_cluster[1]]
# }



