# =============================================================================
# OUTPUTS — Users
# =============================================================================

output "user_juliana_dev_arn" {
  description = "ARN do usuário IAM juliana-dev"
  value       = aws_iam_user.juliana_dev.arn
}

output "user_rafael_platform_arn" {
  description = "ARN do usuário IAM rafael-platform"
  value       = aws_iam_user.rafael_platform.arn
}

output "user_lucas_intern_arn" {
  description = "ARN do usuário IAM lucas-intern"
  value       = aws_iam_user.lucas_intern.arn
}

output "all_user_arns" {
  description = "Mapa com todos os ARNs de usuários IAM criados"
  value = {
    juliana_dev     = aws_iam_user.juliana_dev.arn
    rafael_platform = aws_iam_user.rafael_platform.arn
    lucas_intern    = aws_iam_user.lucas_intern.arn
  }
}

# =============================================================================
# OUTPUTS — Groups
# =============================================================================

output "group_developers_arn" {
  description = "ARN do grupo IAM developers"
  value       = aws_iam_group.developers.arn
}

output "group_platform_eng_arn" {
  description = "ARN do grupo IAM platform-eng"
  value       = aws_iam_group.platform_eng.arn
}

# =============================================================================
# OUTPUTS — Policies
# =============================================================================

output "policy_s3_read_arn" {
  description = "ARN da policy SEURA-technova-s3-read"
  value       = aws_iam_policy.s3_read.arn
}

output "policy_ec2_s3_full_arn" {
  description = "ARN da policy SEURA-technova-ec2-s3-full"
  value       = aws_iam_policy.ec2_s3_full.arn
}

output "policy_deny_destructive_arn" {
  description = "ARN da policy SEURA-technova-deny-destructive"
  value       = aws_iam_policy.deny_destructive.arn
}

output "policy_ec2_role_s3_app_data_arn" {
  description = "ARN da policy de permissão da EC2 role (S3 app data)"
  value       = aws_iam_policy.ec2_role_s3_app_data.arn
}

# =============================================================================
# OUTPUTS — Role e Instance Profile
# =============================================================================

output "ec2_role_arn" {
  description = "ARN da IAM Role SEURA-technova-ec2-role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_role_name" {
  description = "Nome da IAM Role SEURA-technova-ec2-role"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_arn" {
  description = "ARN do Instance Profile SEURA-technova-ec2-profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "ec2_instance_profile_name" {
  description = "Nome do Instance Profile para uso no launch de instâncias EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}
