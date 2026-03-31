
output "node_iam_instance_profile_master" {
  value = aws_iam_instance_profile.node_ssm_instance_profile.name
}
output "node_iam_instance_profile_worker" {
  value = aws_iam_instance_profile.worker_instance_profile.name
}