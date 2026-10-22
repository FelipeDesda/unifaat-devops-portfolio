# Aula 10 - Terraform Automatizado e CD Pipelines
## GitOps + Continuous Delivery Completo

[![Terraform Plan](https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions/workflows/terraform-plan.yml)
[![Terraform Apply](https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions/workflows/terraform-apply.yml)
[![CD Pipeline](https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions/workflows/cd.yml/badge.svg)](https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions/workflows/cd.yml)

---

## 📋 Sobre o Projeto

Implementação completa de **GitOps** e **Continuous Delivery** para a aplicação TechNova API, incluindo:

- ✅ Terraform GitOps (plan automático em PRs, apply no merge)
- ✅ Pipeline CD completo (lint → test → build → push → deploy)
- ✅ Deploy automatizado na EC2 com estratégia Recreate
- ✅ Health check pós-deploy com retry
- ✅ Autenticação AWS via credenciais de sessão do Learner Lab
- ✅ Rollback documentado e testado

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         GitHub                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Pull Request │  │ Push to Main │  │ Push to Main │      │
│  │  (.tf files) │  │  (.tf files) │  │  (app files) │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         ▼                  ▼                  ▼              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Terraform    │  │ Terraform    │  │  CD Pipeline │      │
│  │ Plan         │  │ Apply        │  │              │      │
│  │ (validate)   │  │ (execute)    │  │ lint → test  │      │
│  └──────┬───────┘  └──────┬───────┘  │ build → push │      │
│         │                  │          │ deploy       │      │
│         ▼                  │          └──────┬───────┘      │
│  Comment no PR             │                  │              │
│                            ▼                  │              │
└────────────────────────────┼──────────────────┼──────────────┘
                             │                  │
                             ▼                  ▼
                    ┌─────────────────────────────────┐
                    │         AWS (us-east-1)         │
                    │                                  │
                    │  ┌────────────┐  ┌───────────┐  │
                    │  │    VPC     │  │    ECR    │  │
                    │  │ 10.0.0.0/16│  │ technova- │  │
                    │  │            │  │    api    │  │
                    │  │  ┌──────┐  │  └─────┬─────┘  │
                    │  │  │ EC2  │◄─┼────────┘        │
                    │  │  │ t2.  │  │  (docker pull)  │
                    │  │  │micro │  │                  │
                    │  │  │:3000 │  │                  │
                    │  │  └──────┘  │                  │
                    │  └────────────┘                  │
                    └─────────────────────────────────┘
```

---

## 📁 Estrutura do Projeto

```
aula-10/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml      # Plan automático em PRs
│       ├── terraform-apply.yml     # Apply automático no merge
│       └── cd.yml                  # Pipeline CD completo
│
├── terraform/
│   ├── main.tf                     # Recursos: VPC, EC2, ECR, IAM
│   ├── variables.tf                # Variáveis de entrada
│   ├── outputs.tf                  # Outputs (IPs, URLs)
│   ├── provider.tf                 # Provider AWS + backend
│   └── terraform.tfvars            # Valores das variáveis
│
├── technova-api/                   # Aplicação Node.js
│   ├── server.js                   # Express API
│   ├── package.json                # Dependências
│   ├── __tests__/
│   │   └── server.test.js          # Testes Jest
│   └── .eslintrc.json              # Configuração ESLint
│
├── Dockerfile                      # Multi-stage build
├── docs/
│   └── runbook-rollback.md         # Procedimento de rollback
├── gitops-cd-analise.md            # Análise completa dos conceitos
├── screenshots/                    # Evidências (você vai criar)
│   ├── plan-pr-comment.png
│   ├── apply-success.png
│   ├── cd-pipeline-green.png
│   └── health-check-pass.png
└── README.md                       # Este arquivo
```

---

## 🚀 Como Reproduzir

### Pré-requisitos

- [x] Conta AWS Academy Learner Lab ativa
- [x] Repositório GitHub (fork do unifaat-devops-portfolio)
- [x] Git instalado localmente
- [x] AWS CLI instalado (para testes locais)

### Passo 1: Configurar GitHub Secrets

1. Inicie seu **AWS Lab** (Start Lab no AWS Academy)
2. Clique em **AWS Details** → **Show** nas credenciais
3. Copie as 3 credenciais (elas expiram em 3 horas!)
4. No GitHub, vá em: **Settings** → **Secrets and variables** → **Actions**
5. Adicione os seguintes secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | aws_access_key_id do Lab |
| `AWS_SECRET_ACCESS_KEY` | aws_secret_access_key do Lab |
| `AWS_SESSION_TOKEN` | aws_session_token do Lab |
| `EC2_HOST` | (deixar vazio por enquanto, preencher após Terraform apply) |
| `EC2_USER` | `ec2-user` |
| `EC2_SSH_KEY` | Conteúdo da chave `vockey.pem` (baixar do Lab) |

### Passo 2: Criar Key Pair no AWS

```bash
# No console AWS do Lab:
# EC2 → Key Pairs → vockey (já existe)
# Baixar vockey.pem

# Converter para uso no GitHub Secret (remover quebras de linha):
cat vockey.pem | base64  # Linux/Mac
# ou
Get-Content vockey.pem -Raw | Out-String  # PowerShell

# Copiar output e colar em EC2_SSH_KEY secret
```

### Passo 3: Ajustar Terraform Variables

Edite `aula-10/terraform/terraform.tfvars`:

```hcl
ec2_key_name = "vockey"  # Nome da sua key pair no Lab
allowed_ssh_cidr = "SEU_IP_PUBLICO/32"  # Seu IP (mais seguro)
```

### Passo 4: Aplicar Infraestrutura (Primeira Vez)

**Opção A: Via Workflow (Recomendado)**

```bash
# 1. Criar branch para testar
git checkout -b feature/setup-infra

# 2. Fazer pequena mudança em algum .tf (adicionar comentário)
# Isso vai disparar o workflow terraform-plan.yml

# 3. Commitar e pushar
git add aula-10/terraform/
git commit -m "feat: configura infraestrutura inicial"
git push origin feature/setup-infra

# 4. Abrir Pull Request no GitHub
# 5. Ver o plan como comentário no PR
# 6. Se OK, fazer merge → terraform-apply.yml vai rodar
```

**Opção B: Manual (Primeira Vez)**

```bash
cd aula-10/terraform/

# Configurar credenciais AWS localmente
export AWS_ACCESS_KEY_ID="sua_key"
export AWS_SECRET_ACCESS_KEY="sua_secret"
export AWS_SESSION_TOKEN="seu_token"
export AWS_DEFAULT_REGION="us-east-1"

# Inicializar Terraform
terraform init

# Ver o que será criado
terraform plan

# Aplicar (criar recursos)
terraform apply -auto-approve

# Salvar outputs importantes
terraform output ec2_public_ip      # Copiar este IP
terraform output ecr_repository_url
```

### Passo 5: Atualizar Secret EC2_HOST

Após Terraform criar a EC2:

1. Copie o **Public IP** da EC2 (do output do Terraform ou do console AWS)
2. No GitHub: **Settings** → **Secrets** → Editar `EC2_HOST`
3. Colar o IP público

### Passo 6: Fazer Primeiro Deploy da Aplicação

```bash
# 1. Criar branch
git checkout -b feature/first-deploy

# 2. Fazer pequena mudança na aplicação (opcional)
# Exemplo: adicionar comentário em server.js

# 3. Commitar e pushar
git add aula-10/technova-api/
git commit -m "feat: primeiro deploy da aplicação"
git push origin feature/first-deploy

# 4. Fazer merge para main
# 5. Workflow cd.yml vai executar automaticamente:
#    - lint (ESLint)
#    - test (Jest)
#    - build & push (Docker → ECR)
#    - deploy (SSH → EC2 → docker run)
#    - health check
```

### Passo 7: Verificar Funcionamento

```bash
# Verificar se API está respondendo (substituir pelo IP da sua EC2)
curl http://SEU_EC2_IP:3000/health

# Exemplo de resposta esperada:
# {"status":"ok","timestamp":"2024-10-22T15:00:00.000Z","version":"1.0.0"}

# Testar endpoint de negócio
curl http://SEU_EC2_IP:3000/api/orders
```

---

## 🔄 Fluxo GitOps

### Para Mudanças de Infraestrutura (Terraform)

```bash
# 1. Criar branch
git checkout -b feature/add-rds

# 2. Modificar arquivos .tf
# Exemplo: adicionar recurso RDS em main.tf

# 3. Abrir Pull Request
git add aula-10/terraform/
git commit -m "feat: adiciona banco RDS"
git push origin feature/add-rds

# 4. Workflow terraform-plan.yml executa automaticamente
#    → Plan é postado como comentário no PR

# 5. Time revisa o plan no PR

# 6. Fazer merge para main
#    → Workflow terraform-apply.yml aplica mudanças automaticamente
```

### Para Mudanças de Aplicação (Código)

```bash
# 1. Criar branch
git checkout -b feature/new-endpoint

# 2. Modificar código
# Exemplo: adicionar novo endpoint em server.js

# 3. Rodar testes localmente
cd aula-10/technova-api/
npm install
npm test
npm run lint

# 4. Commitar e pushar
git add aula-10/technova-api/
git commit -m "feat: adiciona endpoint /api/products"
git push origin feature/new-endpoint

# 5. Fazer merge para main
#    → Workflow cd.yml executa:
#      - lint ✅
#      - test ✅
#      - build & push to ECR ✅
#      - deploy to EC2 ✅
#      - health check ✅
```

---

## 🧪 Testando Localmente

### Testar Aplicação

```bash
cd aula-10/technova-api/

# Instalar dependências
npm install

# Rodar testes
npm test

# Rodar lint
npm run lint

# Rodar localmente
npm start

# Testar em outro terminal
curl http://localhost:3000/health
curl http://localhost:3000/api/orders
```

### Testar Docker Build

```bash
cd aula-10/

# Build da imagem
docker build -t technova-api:local -f Dockerfile technova-api/

# Rodar container
docker run -d -p 3000:3000 --name technova-api-local technova-api:local

# Testar
curl http://localhost:3000/health

# Ver logs
docker logs technova-api-local

# Parar e remover
docker stop technova-api-local
docker rm technova-api-local
```

### Testar Terraform Localmente

```bash
cd aula-10/terraform/

# Formatar código
terraform fmt -recursive

# Validar sintaxe
terraform validate

# Ver plan (sem aplicar)
terraform plan

# Ver outputs atuais
terraform output
```

---

## 📸 Screenshots Obrigatórios

Para comprovar o funcionamento, capture:

### 1. Plan como Comentário no PR
- [ ] Abrir PR com mudança em `.tf`
- [ ] Screenshot do comentário do bot com o plan
- [ ] Salvar em `screenshots/plan-pr-comment.png`

### 2. Apply Executado Após Merge
- [ ] Acessar GitHub Actions após merge
- [ ] Screenshot do workflow `terraform-apply.yml` verde
- [ ] Salvar em `screenshots/apply-success.png`

### 3. Pipeline CD Completa Passando
- [ ] Screenshot mostrando todos os jobs verdes:
  - lint ✅
  - test ✅
  - build-push ✅
  - deploy ✅
- [ ] Salvar em `screenshots/cd-pipeline-green.png`

### 4. Health Check Passando
- [ ] Screenshot do log do job `deploy` mostrando:
  - "✅ Health check passou!"
  - Response JSON do /health
- [ ] Salvar em `screenshots/health-check-pass.png`

---

## 🔙 Rollback

Se algo der errado após deploy, consulte: **[docs/runbook-rollback.md](docs/runbook-rollback.md)**

**Rollback rápido (Git Revert)**:
```bash
# 1. Identificar commit problemático
git log --oneline -5

# 2. Reverter
git revert <commit-hash>

# 3. Push
git push origin main

# Pipeline vai rodar automaticamente e fazer rollback
```

**Rollback de emergência (Manual)**:
```bash
# Conectar na EC2
ssh -i vockey.pem ec2-user@<EC2_IP>

# Login no ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ECR_REGISTRY>

# Parar container atual
docker stop technova-api
docker rm technova-api

# Puxar versão anterior
docker pull <ECR_REGISTRY>/technova-api:<SHA_ANTERIOR>

# Rodar versão anterior
docker run -d --name technova-api -p 3000:3000 \
  <ECR_REGISTRY>/technova-api:<SHA_ANTERIOR>
```

---

## 📚 Documentação Adicional

- **[gitops-cd-analise.md](gitops-cd-analise.md)**: Análise completa de conceitos
  - GitOps (por que plan no PR?)
  - Autenticação AWS (Lab vs Produção)
  - Estratégia Recreate (prós/contras)
  - CD vs Continuous Deployment
  - Limitações e melhorias

- **[docs/runbook-rollback.md](docs/runbook-rollback.md)**: Procedimento de rollback
  - 3 métodos de rollback
  - Troubleshooting comum
  - Checklist pós-rollback

---

## 🔧 Troubleshooting

### Problema: Workflow falha com "ExpiredToken"

**Causa**: Sessão do Learner Lab expirou (dura 3 horas)

**Solução**:
1. Voltar ao AWS Academy
2. Clicar em "Start Lab"
3. Copiar novas credenciais (AWS Details)
4. Atualizar GitHub Secrets

---

### Problema: Health check falha após deploy

**Causa**: Aplicação não iniciou corretamente

**Diagnóstico**:
```bash
# Conectar na EC2
ssh -i vockey.pem ec2-user@<EC2_IP>

# Ver se container está rodando
docker ps -a | grep technova-api

# Ver logs
docker logs technova-api
```

**Solução**:
```bash
# Se container parou, ver motivo
docker inspect technova-api

# Remover e rodar novamente
docker rm technova-api
docker run -d --name technova-api -p 3000:3000 <IMAGE>
```

---

### Problema: Não consigo fazer pull da imagem ECR

**Erro**: `no basic auth credentials`

**Causa**: Esqueceu de fazer login no ECR

**Solução**:
```bash
# SEMPRE fazer login antes de docker pull
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ECR_REGISTRY>
```

---

### Problema: Terraform apply falha (state lock)

**Erro**: `Error acquiring the state lock`

**Causa**: Outro apply rodando ou travado

**Solução** (usar com cuidado!):
```bash
# Ver se há workflow rodando no GitHub
# Se não houver, forçar unlock:
terraform force-unlock <LOCK_ID>
```

---

## 📊 Métricas e Monitoramento

### Ver Logs da Aplicação

```bash
# SSH na EC2
ssh -i vockey.pem ec2-user@<EC2_IP>

# Logs em tempo real
docker logs -f technova-api

# Últimas 100 linhas
docker logs technova-api --tail 100

# Filtrar erros
docker logs technova-api 2>&1 | grep -i error
```

### Ver Uso de Recursos

```bash
# Uso de CPU/Memória
docker stats technova-api

# Espaço em disco
df -h

# Processos
ps aux | grep node
```

---

## 🎯 Checklist de Entrega

### Workflows GitHub Actions
- [ ] `terraform-plan.yml` funciona em PR
- [ ] `terraform-apply.yml` funciona após merge
- [ ] `cd.yml` executa todo o pipeline
- [ ] Todos os workflows estão verdes (sem erros)

### Terraform
- [ ] VPC, Subnet, Internet Gateway criados
- [ ] EC2 com Docker instalado
- [ ] Security Group permite portas 22 e 3000
- [ ] IAM Role com acesso ao ECR
- [ ] ECR Repository criado

### Aplicação
- [ ] Testes passam (`npm test`)
- [ ] Lint passa (`npm run lint`)
- [ ] Docker build funciona
- [ ] Imagem no ECR
- [ ] Container rodando na EC2
- [ ] Health check responde

### Documentação
- [ ] `gitops-cd-analise.md` completo
- [ ] `docs/runbook-rollback.md` completo
- [ ] Screenshots salvos
- [ ] README atualizado

### GitHub Secrets
- [ ] AWS_ACCESS_KEY_ID
- [ ] AWS_SECRET_ACCESS_KEY
- [ ] AWS_SESSION_TOKEN
- [ ] EC2_HOST
- [ ] EC2_USER
- [ ] EC2_SSH_KEY

---

## 🏆 Critérios de Excelência (Bônus)

Se quiser ir além:

- [ ] Terraform detect destroy (alerta extra)
- [ ] Comentário do plan é atualizado (não duplicado) ✅ Já implementado
- [ ] Deploy com GITHUB_SHA para rastreabilidade ✅ Já implementado
- [ ] Notificação de deploy (Slack/Discord)
- [ ] `terraform fmt -check` no plan ✅ Já implementado
- [ ] Cost estimation com Infracost
- [ ] Workflow de destroy com aprovação manual
- [ ] GitHub Environment com approval

---

## 📞 Suporte

**Problemas com credenciais AWS**: Renovar sessão no Lab  
**Problemas com workflows**: Verificar logs no GitHub Actions  
**Problemas com EC2**: SSH e verificar logs do Docker

---

## 📝 Licença

Este projeto é parte do curso de DevOps - UNIFAAT.

---

**Autor**: [Seu Nome]  
**RA**: [Seu RA]  
**Data**: Outubro 2024  
**Curso**: DevOps - UNIFAAT
