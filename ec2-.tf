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
  subnet_id                   = random_shuffle.subnets_list.result[count.index]
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["ssh"].id, aws_security_group.grad_proj_sg["http_https"].id, aws_security_group.grad_proj_sg["public"].id] #vpc_security_group_ids      = [ aws_security_group.http-only.id, aws_security_group.ssh-only.id ]
  root_block_device {
    volume_size = 10
  }
  credit_specification {
    cpu_credits = "standard" #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }
  tags = {
    "Name"      = "master-node-${count.index}"
    "master"    = "true"
    "terraform" = "true"
  }
  #  provisioner "local-exec" {
  #    when    = destroy
  #    command = "kubectl config delete-context ahmed@cloud-cluster ; kubectl config delete-user ahmed-admin ; kubectl config delete-cluster cloud-cluster"
  #  }
}

resource "aws_eip" "master_nodes_eips" {
  count = 1
  tags = {
    "Name"   = "master-node-${count.index}-eip"
    "master" = "true"
  }
}

resource "aws_eip_association" "master_nodes_eips_assoc" {
  count         = 1
  instance_id   = aws_instance.master_nodes.*.id[count.index]
  allocation_id = aws_eip.master_nodes_eips.*.id[count.index]
}

data "aws_eips" "masters_eips" {
  depends_on = [null_resource.kube_cluster]
  tags = {
    "Name" = "*master*"
  }
}

output "masters_eips" {
  value = data.aws_eips.masters_eips.public_ips
}

resource "aws_instance" "worker_nodes" {
  count                       = local.worker_nodes_count
  ami                         = data.aws_ami.ubuntu_ami.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = random_shuffle.subnets_list.result[count.index]
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["ssh"].id, aws_security_group.grad_proj_sg["http_https"].id, aws_security_group.grad_proj_sg["public"].id] #vpc_security_group_ids      = [ aws_security_group.http-only.id, aws_security_group.ssh-only.id ]
  root_block_device {
    volume_size = 10
  }
  credit_specification {
    cpu_credits = "standard" #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }
  tags = {
    "Name"      = "worker-node-${count.index}"
    "terraform" = "true"
    "worker"    = "true"
  }
}

resource "aws_eip" "worker_nodes_eips" {
  count = local.worker_nodes_count
  tags = {
    "Name"   = "worker-node-${count.index}-eip"
    "worker" = "true"
  }
}

resource "aws_eip_association" "worker_nodes_eips_assoc" {
  count         = local.worker_nodes_count
  instance_id   = aws_instance.worker_nodes.*.id[count.index]
  allocation_id = aws_eip.worker_nodes_eips.*.id[count.index]
}

data "aws_eips" "workers_eips" {
  depends_on = [null_resource.kube_cluster]
  tags = {
    "worker" = "true"
  }
}

output "workers_eips" {
  value = data.aws_eips.workers_eips.public_ips
}


#resource "null_resource" "ssh_config" {
#  provisioner "local-exec" {
#    interpreter = ["/bin/bash", "-c"]
#    command     = <<EOT
#     export master_public_ip=${aws_instance.master_nodes[0].public_ip}  worker1_public_ip=${aws_instance.worker_nodes[0].public_ip} worker2_public_ip=${aws_instance.worker_nodes[1].public_ip}
#     envsubst '$master_public_ip,$worker1_public_ip,$worker2_public_ip'  <  ./ssh-config-vars  >  ./ssh-config
#     cp ssh-config ~/.ssh/config
#    EOT
#  }
#  depends_on = [aws_instance.master_nodes[0], aws_instance.worker_nodes[0], aws_instance.worker_nodes[1]]
#  lifecycle {
#    replace_triggered_by = [aws_instance.master_nodes[0], aws_instance.worker_nodes[0], aws_instance.worker_nodes[1]]
#  }
#}

resource "null_resource" "kube_cluster" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT

echo '' > ./kubernetes-2/master_nodes;
for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4`; do aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*master*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text >> ./kubernetes-2/master_nodes ; done;
sed -i '/^$/d' ./kubernetes-2/master_nodes
echo '' > ./kubernetes-2/worker_nodes;
for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4`; do aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*worker*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text >> ./kubernetes-2/worker_nodes ; done;
sed -i '/^$/d' ./kubernetes-2/worker_nodes
echo [master_nodes] > kubernetes-2/kubernetes_cluster;
cat kubernetes-2/master_nodes >> kubernetes-2/kubernetes_cluster;
echo [worker_nodes] >> kubernetes-2/kubernetes_cluster;
cat kubernetes-2/worker_nodes >> kubernetes-2/kubernetes_cluster;

#Another solution
#echo > ./kubernetes-2/tmp_master_nodes;
#for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4`; do aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*master*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text >> ./kubernetes-2/tmp_master_nodes; done;
#sed '/^[[:space:]]*$/d' ./kubernetes-2/tmp_master_nodes > ./kubernetes-2/master_nodes;
#echo > ./kubernetes-2/tmp_worker_nodes;
#for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4`; do aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*worker*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text >> ./kubernetes-2/tmp_worker_nodes; done;
#sed '/^[[:space:]]*$/d' ./kubernetes-2/tmp_worker_nodes > ./kubernetes-2/worker_nodes
#echo [master_nodes] > kubernetes-2/kubernetes_cluster;
#cat kubernetes-2/master_nodes >> kubernetes-2/kubernetes_cluster;
#echo [worker_nodes] >> kubernetes-2/kubernetes_cluster;
#cat kubernetes-2/worker_nodes >> kubernetes-2/kubernetes_cluster;

#configure ssh config file on the local host
echo "Host *" > ssh_config_file  ;  echo "    StrictHostKeyChecking no" >> ssh_config_file;
j=0; for i in $(cat kubernetes-2/master_nodes); do  echo "Host master$j"; echo "    HostName $i"; echo "    User ubuntu"; echo "    Port 22"; echo "    StrictHostKeyChecking no"; let j+=1 ; done >> ssh_config_file;
j=0; for i in $(cat kubernetes-2/worker_nodes); do  echo "Host worker$j"; echo "    HostName $i"; echo "    User ubuntu"; echo "    Port 22"; echo "    StrictHostKeyChecking no"; let j+=1 ; done >> ssh_config_file;
cp ssh_config_file ~/.ssh/config;

#set hostname for the cluster nodes
j=0; for i in `cat kubernetes-2/master_nodes`; do ssh ubuntu@$i "sudo hostnamectl hostname master$j"; let j+=1 ; done;
j=0; for i in `cat kubernetes-2/worker_nodes`; do ssh ubuntu@$i "sudo hostnamectl hostname worker$j"; let j+=1 ; done;

#Another solution
#echo "[master_nodes]" > ./kubernetes-2/kubernetes_cluster
#for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4` ; do  aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*master*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text >> ./kubernetes-2/kubernetes_cluster ; done
#echo "[worker_nodes]" >> ./kubernetes-2/kubernetes_cluster
#for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4` ; do  aws ec2 describe-instances --region $region --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*worker*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text >> ./kubernetes-2/kubernetes_cluster ; done

#Anther solution
#for i in $(aws --region us-east-2 ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*master*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text) ;  do  echo $i >> ./kubernetes-2/kubernetes_cluster ; done
##echo ${aws_instance.master_nodes[0].public_ip} >> ./kubernetes-2/kubernetes_cluster
#echo "[worker_nodes]" >> ./kubernetes-2/kubernetes_cluster
#for i in $(aws --region us-east-2 ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*worker*" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text) ; do  echo $i >> ./kubernetes-2/kubernetes_cluster ; done

#echo ${aws_instance.worker_nodes[0].public_ip} >> ./kubernetes-2/kubernetes_cluster  ;  echo ${aws_instance.worker_nodes[1].public_ip} >> ./kubernetes-2/kubernetes_cluster

#sleep 100
ansible-playbook --inventory ./kubernetes-2/kubernetes_cluster --user ubuntu ./kubernetes-2/master-node.yml

    EOT
  }
  depends_on = [aws_instance.master_nodes[0], aws_instance.worker_nodes[0], aws_instance.worker_nodes[1]]
  #  depends_on = [aws_instance.master_nodes[0], join(",", aws_instance.worker_nodes[*].id)]

  lifecycle {
    replace_triggered_by = [aws_instance.master_nodes[0], aws_instance.worker_nodes[0], aws_instance.worker_nodes[1]]
  }
  triggers = {
    cluster_instance_ids = join(",", aws_instance.worker_nodes[*].id)
  }
}



resource "null_resource" "configure_kubeconfig_on_host" {
  provisioner "local-exec" {
    command = <<EOT
scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/etc/kubernetes/pki/ca.crt ./kubernetes-2/kube-certs/ca.crt
scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/home/ubuntu/kube-certs/ahmed.crt ./kubernetes-2/kube-certs/ahmed.crt
ssh ubuntu@${aws_instance.master_nodes[0].public_ip} 'cat /home/ubuntu/kube-certs/ahmed.key' > ./kubernetes-2/kube-certs/ahmed.key
kubectl config set-cluster cloud-cluster --certificate-authority=./kubernetes-2/kube-certs/ca.crt --server=https://${aws_instance.master_nodes[0].public_ip}:51555
kubectl config set-credentials ahmed --client-certificate=./kubernetes-2/kube-certs/ahmed.crt --client-key=./kubernetes-2/kube-certs/ahmed.key
kubectl config set-context ahmed@cloud-cluster --cluster=cloud-cluster --user=ahmed --namespace=default
kubectl config use-context ahmed@cloud-cluster
    EOT
  }
  depends_on = [null_resource.kube_cluster]
}




resource "null_resource" "exprimental_2" {
  depends_on = [null_resource.kube_cluster]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT

echo '' > f2
%{for ip in data.aws_eips.workers_eips.public_ips}
echo "${ip}" >> f2
%{endfor}
sed -i '/^$/d' f2

echo '' > f1
%{for ip in aws_eip.worker_nodes_eips.*.public_ip}
echo "${ip}" >> f1
%{endfor}
sed -i '/^$/d' f1

echo '' > ./kubernetes-2/terraform_output_master_nodes
terraform output -json masters_eips | jq -r ".[0]" >> ./kubernetes-2/terraform_output_master_nodes
sed -i '/^$/d' ./kubernetes-2/terraform_output_master_nodes
echo '' > ./kubernetes-2/terraform_output_worker_nodes
for i in $(seq 0 $((${local.worker_nodes_count}-1))); do    terraform output -json workers_eips | jq -r ".[$i]" >> ./kubernetes-2/terraform_output_worker_nodes ; done
sed -i '/^$/d' ./kubernetes-2/terraform_output_worker_nodes

    EOT
  }
}

#This aitnt working man ---> it will write both ips in one line man
#for region in `aws ec2 describe-regions --region us-east-1 --output text | cut -f4`; do aws ec2 describe-addresses --region $region --filters "Name=tag:Name,Values=*worker*" --query 'Addresses[*].PublicIp' --output text >> f22 ; done

#echo > f1 === echo "" > f1    ---> wil print empty line in the file mane
#echo '' > f1                  ---> will not print space in the file man

#echo ${data.aws_eips.masters_eips.public_ips} > /home/ahmed/Desktop/terraform/kubernetes-cluster-roles/kubernetes-2/terraform_output_master_nodes
#echo ${data.aws_eips.workers_eips.public_ips} > /home/ahmed/Desktop/terraform/kubernetes-cluster-roles/kubernetes-2/terraform_output_worker_nodes

# curl $(terraform output -raw lb_url)
# terraform output -json workers_eips | jq -r '.[0]'




#resource "null_resource" "kube_cluster_3" {
#  provisioner "local-exec" {
#    command =  <<EOT
#export  master_public_ip=${aws_instance.master_nodes[0].public_ip}   master_private_ip=${aws_instance.master_nodes[0].private_ip}  worker1_public_ip=${aws_instance.worker_nodes[0].public_ip}  worker1_private_ip=${aws_instance.worker_nodes[0].private_ip} worker2_public_ip=${aws_instance.worker_nodes[1].public_ip}  worker2_private_ip=${aws_instance.worker_nodes[1].private_ip}
#envsubst '$master_public_ip,$master_private_ip'                                                                               < ./kubernetes-2/roles/kubernetes-master/tasks/main-vars.yml > ./kubernetes-2/roles/kubernetes-master/tasks/main.yml
#envsubst '$master_public_ip,$worker1_public_ip,$worker2_public_ip'                                                            < ./kubernetes-2/roles/kubernetes-worker/tasks/main-vars.yml > ./kubernetes-2/roles/kubernetes-worker/tasks/main.yml
#envsubst '$master_public_ip,$master_private_ip,$worker1_public_ip,$worker1_private_ip,$worker2_public_ip,$worker2_private_ip' < ./kubernetes-2/master-node-vars.yml                        > ./kubernetes-2/master-node.yml
#sleep 100
#ansible-playbook --inventory ${aws_instance.master_nodes[0].public_ip},${aws_instance.worker_nodes[0].public_ip},${aws_instance.worker_nodes[1].public_ip} --user ubuntu ./kubernetes-2/master-node.yml
#    EOT
#  }
#  depends_on = [aws_instance.master_nodes[0],aws_instance.worker_nodes[0],aws_instance.worker_nodes[1]]
#}


#resource "null_resource" "configure_kubeconfig_on_host" {
#  provisioner "local-exec" {
#    command = <<EOT
#scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/etc/kubernetes/pki/ca.crt ./kubernetes-2/kube-certs/ca.crt
#scp ubuntu@${aws_instance.master_nodes[0].public_ip}:/home/ubuntu/kube-certs/ahmed.crt ./kubernetes-2/kube-certs/ahmed.crt
#ssh ubuntu@${aws_instance.master_nodes[0].public_ip} 'cat /home/ubuntu/kube-certs/ahmed.key' > ./kubernetes-2/kube-certs/ahmed.key
#kubectl config set-cluster cloud-cluster --certificate-authority=./kubernetes-2/kube-certs/ca.crt --server=https://${aws_instance.master_nodes[0].public_ip}:51555
#kubectl config set-credentials ahmed --client-certificate=./kubernetes-2/kube-certs/ahmed.crt --client-key=./kubernetes-2/kube-certs/ahmed.key
#kubectl config set-context ahmed@cloud-cluster --cluster=cloud-cluster --user=ahmed --namespace=default
#kubectl config use-context ahmed@cloud-cluster
#    EOT
#  }
#  depends_on = [null_resource.kube_cluster]
#}



#echo ${aws_eip.master_nodes_eips[*].public_ip} > ./kubernetes-2/terraform_output_master_nodes
#echo ${aws_eip.worker_nodes_eips[0].public_ip} > ./kubernetes-2/terraform_output_worker_nodes


#echo ${data.aws_eips.masters_eips.public_ips} > /home/ahmed/Desktop/terraform/kubernetes-cluster-roles/kubernetes-2/terraform_output_master_nodes
#echo ${data.aws_eips.workers_eips.public_ips} > /home/ahmed/Desktop/terraform/kubernetes-cluster-roles/kubernetes-2/terraform_output_worker_nodes

#echo ${data.aws_eips.masters_eips.public_ips} > /home/ahmed/Desktop/terraform/kubernetes-cluster-roles/kubernetes-2/terraform_output_master_nodes;
#echo ${aws_eip.master_nodes_eips.*.id} > ./kubernetes-2/terraform_output_master_nodes
#echo ${aws_eip.worker_nodes_eips.*.id} > ./kubernetes-2/terraform_output_worker_nodes



#rm -f ./kubernetes-2/terraform_output_master_nodes
#for (( c=0; c<=${local.master_nodes_count}; c++ )); do
#echo "${aws_eip.master_nodes_eips[$c].public_ip}" >> ./kubernetes-2/terraform_output_master_nodes
#done
#
#rm -f ./kubernetes-2/terraform_output_worker_nodes
#for (( c=0; c<=${local.worker_nodes_count}; c++ )); do
#echo "${aws_eip.worker_nodes_eips[$c].public_ip}" >> ./kubernetes-2/terraform_output_worker_nodes
#done

