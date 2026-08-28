# =============================================================================
# IAM GROUPS
# =============================================================================

resource "aws_iam_group" "developers" {
  name = "SEURA-technova-developers"
  path = "/technova/"
}

resource "aws_iam_group" "platform_eng" {
  name = "SEURA-technova-platform-eng"
  path = "/technova/"
}

# =============================================================================
# IAM USERS
# =============================================================================

resource "aws_iam_user" "juliana_dev" {
  name = "SEURA-juliana-dev"
  path = "/technova/"

  tags = {
    Role = "Developer"
  }
}

resource "aws_iam_user" "rafael_platform" {
  name = "SEURA-rafael-platform"
  path = "/technova/"

  tags = {
    Role = "Platform Engineer"
  }
}

resource "aws_iam_user" "lucas_intern" {
  name = "SEURA-lucas-intern"
  path = "/technova/"

  tags = {
    Role = "Intern"
  }
}

# =============================================================================
# GROUP MEMBERSHIPS
# =============================================================================

# juliana-dev → apenas developers
resource "aws_iam_user_group_membership" "juliana_membership" {
  user = aws_iam_user.juliana_dev.name

  groups = [
    aws_iam_group.developers.name,
  ]
}

# rafael-platform → developers + platform-eng
resource "aws_iam_user_group_membership" "rafael_membership" {
  user = aws_iam_user.rafael_platform.name

  groups = [
    aws_iam_group.developers.name,
    aws_iam_group.platform_eng.name,
  ]
}

# lucas-intern → apenas developers (política restritiva aplicada diretamente)
resource "aws_iam_user_group_membership" "lucas_membership" {
  user = aws_iam_user.lucas_intern.name

  groups = [
    aws_iam_group.developers.name,
  ]
}
