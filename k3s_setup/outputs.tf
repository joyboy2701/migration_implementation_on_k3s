
################################
# K3s Master
################################

output "k3s_master_private_ip" {
  value = module.k3s_cluster.k3s_master_private_ip
}

################################
# K3s Workers
################################

output "k3s_worker_private_ips" {
  value = module.k3s_cluster.k3s_worker_private_ips
}
