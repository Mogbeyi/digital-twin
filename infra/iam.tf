# =============================================================================
# IAM Configuration
# =============================================================================
#
# NOTE: The digital-twin-deployer user was created MANUALLY (for learning)
# and is now managed outside of Terraform.
#
# This file contains ONLY the IAM roles that Terraform needs to create
# for the application itself (not for CI/CD deployment).
#
# If you want Terraform to manage the deployer user in the future,
# you can import it with:
#   terraform import aws_iam_user.deployer digital-twin-deployer
# =============================================================================

# The IAM roles for App Runner are defined in:
# - apprunner.tf  (aws_iam_role.apprunner_ecr_access)
# - secrets.tf    (aws_iam_role.apprunner_instance)
