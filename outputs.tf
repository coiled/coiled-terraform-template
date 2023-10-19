output "coiled_role_arn" {
  value = aws_iam_role.coiled_control_plane_role.arn
}
output "coiled_external_id" {
  value = random_id.external_id.hex
}
output "coiled_instance_profile_arn" {
  value = aws_iam_instance_profile.coiled_cluster_instance_profile.arn
}
output "coiled_vpc_id" {
  value = aws_vpc.main.id
}
output "coiled_subnet_ids" {
  value = values(aws_subnet.public_subnet)[*].id
}
output "coiled_scheduler_sg" {
  value = aws_security_group.scheduler_security_group.id
}
output "coiled_cluster_sg" {
  value = aws_security_group.cluster_security_group.id
}
