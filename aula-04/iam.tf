# ============================================================
# IAM — AWS Academy (voclabs) nao permite criar roles nem
# instance profiles. Referenciamos o LabInstanceProfile
# pre-existente via data source, sem criar nenhum recurso.
# ============================================================

data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}
