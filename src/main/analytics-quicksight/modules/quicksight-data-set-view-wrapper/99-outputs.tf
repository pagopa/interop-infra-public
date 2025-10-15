
output "data_set_arn" {
  description = "Contains the ARN of the QuickSight dataset created by this module"
  value       = aws_quicksight_data_set.data_set.arn
}

