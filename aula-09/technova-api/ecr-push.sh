#!/usr/bin/env bash
set -euo pipefail

# ---- Configuração ----
REGION="us-east-1"
REPO="technova-api"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO"

# Tag pelo SHA curto do commit (rastreabilidade total)
SHA_TAG="sha-$(git rev-parse --short HEAD)"

echo "==> Garantindo o repositório ECR ($REPO)..."
aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --region "$REGION" >/dev/null

echo "==> Login no ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "==> Build..."
docker build -t "$REPO:local" .

echo "==> Tag ($SHA_TAG + latest) e push..."
docker tag "$REPO:local" "$ECR_URI:$SHA_TAG"
docker tag "$REPO:local" "$ECR_URI:latest"
docker push "$ECR_URI:$SHA_TAG"
docker push "$ECR_URI:latest"

echo "==> Pronto! Imagem publicada:"
echo "    $ECR_URI:$SHA_TAG"
echo "    $ECR_URI:latest"