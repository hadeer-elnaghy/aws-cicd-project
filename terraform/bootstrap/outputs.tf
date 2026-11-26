output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_region" {
  description = "Region of the Terraform remote state bucket"
  value       = aws_s3_bucket.terraform_state.region
}

output "aws_account_id" {
  description = "AWS account ID used in the bucket name"
  value       = data.aws_caller_identity.current.account_id
}
