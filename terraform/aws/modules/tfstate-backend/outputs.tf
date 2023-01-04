output "s3_bucket_domain_name" {
  value       = join("", aws_s3_bucket.backend.*.bucket_domain_name)
  description = "S3 bucket domain name"
}

output "s3_bucket_id" {
  value       = join("", aws_s3_bucket.backend.*.id)
  description = "S3 bucket ID"
}

output "s3_bucket_arn" {
  value       = join("", aws_s3_bucket.backend.*.arn)
  description = "S3 bucket ARN"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.lock.name
  description = "DynamoDB table name"
}

output "dynamodb_table_id" {
  value       = aws_dynamodb_table.lock.id
  description = "DynamoDB table ID"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.lock.arn
  description = "DynamoDB table ARN"
}
