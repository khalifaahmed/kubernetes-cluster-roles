# EC2 Instances
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

resource "aws_instance" "master_nodes" {
  count                       = 1
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
    cpu_credits = "standard"  #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }
  tags = {
    "Name" = "master-node-${count.index}"
  }
#  provisioner "local-exec" {
#    when    = destroy
#    command = "kubectl config delete-context ahmed@cloud-cluster ; kubectl config delete-user ahmed-admin ; kubectl config delete-cluster cloud-cluster"
#  }
}

resource "aws_instance" "worker_nodes" {
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
    cpu_credits = "standard"  #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }
  tags = {
    "Name" = "worker-node-${count.index}"
  }
}

resource "null_resource" "ssh_config_3" {
  provisioner "local-exec" {
    command = <<EOT
     export master_public_ip=${aws_instance.master_nodes[0].public_ip}  \
            worker1_public_ip=${aws_instance.worker_nodes[0].public_ip} \
            worker2_public_ip=${aws_instance.worker_nodes[1].public_ip}
     envsubst '$master_public_ip,$worker1_public_ip,$worker2_public_ip' < ./ssh-config-vars > ./ssh-config
     cp ssh-config ~/.ssh/config
    EOT
    #"export master_public_ip=${aws_instance.master_nodes[0].public_ip}  worker1_public_ip=${aws_instance.worker_nodes[0].public_ip} worker2_public_ip=${aws_instance.worker_nodes[1].public_ip} ; envsubst '$master_public_ip,$worker1_public_ip,$worker2_public_ip' < ./ssh-config-vars > ./ssh-config ; cp ssh-config ~/.ssh/config"
  }
  depends_on = [aws_instance.master_nodes[0],
                aws_instance.worker_nodes[0],
                aws_instance.worker_nodes[1]]
  lifecycle {
    replace_triggered_by = [aws_instance.master_nodes[0],
                            aws_instance.worker_nodes[0]]
  }
}

#resource "null_resource" "kube_cluster" {
#  provisioner "local-exec" {
#    command =  <<EOT
#export  master_public_ip=${aws_instance.master_nodes[0].public_ip}   master_private_ip=${aws_instance.master_nodes[0].private_ip}  \
#        worker1_public_ip=${aws_instance.worker_nodes[0].public_ip}  worker1_private_ip=${aws_instance.worker_nodes[0].private_ip} \
#        worker2_public_ip=${aws_instance.worker_nodes[1].public_ip}  worker2_private_ip=${aws_instance.worker_nodes[1].private_ip}
#echo "[master_nodes]" > ./kubernetes-2/kubernetes_cluster
#echo ${aws_instance.master_nodes[0].public_ip} >> ./kubernetes-2/kubernetes_cluster
#echo "[worker_nodes]" >> ./kubernetes-2/kubernetes_cluster
#echo ${aws_instance.worker_nodes[0].public_ip} >> ./kubernetes-2/kubernetes_cluster
#echo ${aws_instance.worker_nodes[1].public_ip} >> ./kubernetes-2/kubernetes_cluster
##envsubst '$master_public_ip,$master_private_ip' < ./kubernetes-2/roles/kubernetes-master/tasks/main-vars.yml > ./kubernetes-2/roles/kubernetes-master/tasks/main.yml
##envsubst '$master_public_ip,$worker1_public_ip,$worker2_public_ip' < ./kubernetes-2/roles/kubernetes-worker/tasks/main-vars.yml > ./kubernetes-2/roles/kubernetes-worker/tasks/main.yml
##envsubst '$master_public_ip,$master_private_ip,$worker1_public_ip,$worker1_private_ip,$worker2_public_ip,$worker2_private_ip' < ./kubernetes-2/master-node-vars.yml > ./kubernetes-2/master-node.yml
#sleep 100
#ansible-playbook \
#--inventory ./kubernetes-2/kubernetes_cluster \
#--user ubuntu \
#./kubernetes-2/master-node.yml
#    EOT
#  }
#  depends_on = [aws_instance.master_nodes[0],aws_instance.worker_nodes[0],aws_instance.worker_nodes[1]]
#  lifecycle {
#    replace_triggered_by = [aws_instance.master_nodes[0],aws_instance.worker_nodes[0],aws_instance.worker_nodes[1]]
#  }
#}

resource "null_resource" "kube_cluster_3" {
  provisioner "local-exec" {
    command =  <<EOT
export  master_public_ip=${aws_instance.master_nodes[0].public_ip}   master_private_ip=${aws_instance.master_nodes[0].private_ip}  \
        worker1_public_ip=${aws_instance.worker_nodes[0].public_ip}  worker1_private_ip=${aws_instance.worker_nodes[0].private_ip} \
        worker2_public_ip=${aws_instance.worker_nodes[1].public_ip}  worker2_private_ip=${aws_instance.worker_nodes[1].private_ip}
envsubst '$master_public_ip,$master_private_ip'                                                                               < ./kubernetes-2/roles/kubernetes-master/tasks/main-vars.yml > ./kubernetes-2/roles/kubernetes-master/tasks/main.yml
envsubst '$master_public_ip,$worker1_public_ip,$worker2_public_ip'                                                            < ./kubernetes-2/roles/kubernetes-worker/tasks/main-vars.yml > ./kubernetes-2/roles/kubernetes-worker/tasks/main.yml
envsubst '$master_public_ip,$master_private_ip,$worker1_public_ip,$worker1_private_ip,$worker2_public_ip,$worker2_private_ip' < ./kubernetes-2/master-node-vars.yml                        > ./kubernetes-2/master-node.yml
sleep 100
ansible-playbook \
--inventory ${aws_instance.master_nodes[0].public_ip},${aws_instance.worker_nodes[0].public_ip},${aws_instance.worker_nodes[1].public_ip} \
--user ubuntu \
./kubernetes-2/master-node.yml
    EOT
  }
  depends_on = [aws_instance.master_nodes[0],aws_instance.worker_nodes[0],aws_instance.worker_nodes[1]]
  lifecycle {
    replace_triggered_by = [aws_instance.master_nodes[0],aws_instance.worker_nodes[0],aws_instance.worker_nodes[1]]
  }
}

#resource "null_resource" "configure_kubeconfig_on_host" {
#  provisioner "local-exec" {
#    command = <<EOT
#scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/etc/kubernetes/pki/ca.crt ./kubernetes-2/kube-certs/ca.crt
#scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/etc/kubernetes/pki/apiserver-etcd-client.crt ./kubernetes-2/kube-certs/client.crt
#ssh ubuntu@${aws_instance.master_nodes[0].public_ip} 'sudo cat /etc/kubernetes/pki/apiserver-etcd-client.key' > ./kubernetes-2/kube-certs/client.key
#kubectl config set-cluster cloud-cluster --certificate-authority=./kubernetes-2/kube-certs/ca.crt --server=https://${aws_instance.master_nodes[0].public_ip}:51555
#kubectl config set-credentials ahmed-admin --client-certificate=./kubernetes-2/kube-certs/client.crt --client-key=./kubernetes-2/kube-certs/client.key
#kubectl config set-context ahmed@cloud-cluster --cluster=cloud-cluster --user=ahmed-admin --namespace=default
#kubectl config use-context ahmed@cloud-cluster
#    EOT
#    #"scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/etc/kubernetes/pki/ca.crt ./kubernetes-2/kube-certs/ca.crt ; scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/etc/kubernetes/pki/apiserver-etcd-client.crt ./kubernetes-2/kube-certs/client.crt ; ssh ubuntu@${aws_instance.master_nodes[0].public_ip} 'sudo cat /etc/kubernetes/pki/apiserver-etcd-client.key' > ./kubernetes-2/kube-certs/client.key ;  kubectl config set-cluster cloud-cluster --certificate-authority=./kubernetes-2/kube-certs/ca.crt --server=https://${aws_instance.master_nodes[0].public_ip}:51555 ; kubectl config set-credentials ahmed-admin --client-certificate=./kubernetes-2/kube-certs/client.crt --client-key=./kubernetes-2/kube-certs/client.key ; kubectl config set-context ahmed@cloud-cluster --cluster=cloud-cluster --user=ahmed-admin --namespace=default ; kubectl config use-context ahmed@cloud-cluster"
#  }
#  depends_on = [null_resource.kube_cluster]
#}

