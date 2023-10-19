resource "aws_cloudwatch_log_group" "cluster_log_group" {
  name              = var.coiled_workspace_name
  retention_in_days = 30
}
