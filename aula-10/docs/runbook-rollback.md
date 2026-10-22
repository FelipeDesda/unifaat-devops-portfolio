# Runbook de Rollback - TechNova API
## Procedimento de Emergência para Reversão de Deploy

---

## 📋 Índice Rápido
- [Método 1: Rollback via Git Revert (Recomendado)](#método-1-rollback-via-git-revert)
- [Método 2: Rollback Manual de Imagem Docker](#método-2-rollback-manual-de-imagem-docker)
- [Método 3: Rollback de Infraestrutura Terraform](#método-3-rollback-de-infraestrutura-terraform)
- [Troubleshooting Comum](#troubleshooting-comum)
- [Checklist Pós-Rollback](#checklist-pós-rollback)

---

## ⚡ Decisão Rápida: Qual Método Usar?

| Situação | Método | Tempo | Downtime |
|----------|--------|-------|----------|
| **Bug no último deploy** | Git Revert | ~5 min | Sim (~30s) |
| **Emergência (produção down)** | Manual Docker | ~2 min | Sim (~30s) |
| **Problema de infraestrutura** | Terraform Revert | ~10 min | Depende |
| **Infraestrutura destruída** | Terraform Apply anterior | ~15 min | Sim |

---

## Método 1: Rollback via Git Revert
### ✅ Quando Usar
- Bug foi introduzido no último ou penúltimo commit
- Você tem tempo (não é emergência crítica)
- Quer manter histórico completo no Git

### 🕐 Tempo Estimado
5-8 minutos (inclui pipeline completa)

### 📝 Procedimento

#### Passo 1: Identificar o Commit Problemático

```bash
# No seu terminal local
cd ~/DEVOPS/unifaat-devops-portfolio

# Listar últimos 10 commits
git log --oneline -10

# Exemplo de output:
# def5678 (HEAD -> main) feat: adiciona validação de email
# abc1234 fix: corrige timeout na API
# 9876543 docs: atualiza README
```

#### Passo 2: Reverter o Commit

```bash
# Reverter o commit problemático (substitua pelo hash real)
git revert def5678

# Editor vai abrir para mensagem de commit
# Adicione contexto:
# "Revert: adiciona validação de email
# 
# Causa: validação estava causando rejeição de emails válidos
# Ticket: #123"

# Salve e feche o editor
```

#### Passo 3: Push do Revert

```bash
# Enviar para o repositório remoto
git push origin main
```

#### Passo 4: Monitorar Pipeline

```bash
# Acompanhar execução no GitHub
# https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions

# Ou via CLI:
gh run list --limit 1
gh run watch  # Acompanhar em tempo real
```

**Pipeline vai executar automaticamente**:
1. ✅ Lint (ESLint)
2. ✅ Test (Jest)
3. ✅ Build & Push (ECR)
4. ✅ Deploy (EC2)
5. ✅ Health Check

#### Passo 5: Validar Rollback

```bash
# Após pipeline concluir (~5 min)
# Testar endpoint de health
curl http://SEU-EC2-IP:3000/health

# Testar endpoints críticos
curl http://SEU-EC2-IP:3000/api/orders
```

### ⚠️ Atenção
- Revert **cria um novo commit** (não apaga o commit problemático)
- Histórico fica limpo e rastreável
- Pipeline passa por todos os testes (mais seguro)

---

## Método 2: Rollback Manual de Imagem Docker
### ✅ Quando Usar
- **EMERGÊNCIA**: Aplicação está down e afetando usuários
- Você precisa da versão anterior **AGORA**
- Git revert demoraria muito

### 🕐 Tempo Estimado
2-3 minutos

### 📝 Procedimento

#### Passo 1: Conectar na EC2

```bash
# Baixar chave do Lab (se ainda não tiver)
# AWS Lab → AWS Details → Download PEM

# Ajustar permissões (Linux/Mac)
chmod 400 ~/Downloads/vockey.pem

# Conectar via SSH
ssh -i ~/Downloads/vockey.pem ec2-user@SEU-EC2-IP

# Windows (PowerShell):
ssh -i C:\Users\SEU_USUARIO\Downloads\vockey.pem ec2-user@SEU-EC2-IP
```

#### Passo 2: Configurar Credenciais AWS na EC2

```bash
# IMPORTANTE: EC2 pode não ter credenciais configuradas
# Configurar usando as credenciais do Lab

# Opção A: Usar IAM Role (se configurado no Terraform)
# Nenhuma ação necessária, EC2 já tem acesso

# Opção B: Configurar manualmente
export AWS_ACCESS_KEY_ID="SUA_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="SUA_SECRET_KEY"
export AWS_SESSION_TOKEN="SEU_SESSION_TOKEN"
export AWS_DEFAULT_REGION="us-east-1"

# Verificar se funcionou
aws sts get-caller-identity
```

#### Passo 3: Login no Amazon ECR

```bash
# Obter account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Definir variáveis
AWS_REGION="us-east-1"
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ECR_REPOSITORY="technova-api"

# Login no ECR (OBRIGATÓRIO antes de docker pull)
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Output esperado:
# Login Succeeded
```

#### Passo 4: Listar Versões Disponíveis

```bash
# Listar todas as imagens no ECR (ordenadas por data)
aws ecr describe-images \
  --repository-name $ECR_REPOSITORY \
  --region $AWS_REGION \
  --query 'sort_by(imageDetails,& imagePushedAt)[*].[imageTags[0],imagePushedAt]' \
  --output table

# Exemplo de output:
# ----------------------------------------------------------
# |                    DescribeImages                       |
# +--------------+------------------------------------------+
# | abc1234def   |  2024-10-20T10:00:00.000000+00:00       | ← Versão ANTERIOR (boa)
# | ghi5678jkl   |  2024-10-22T14:30:00.000000+00:00       | ← Versão ATUAL (ruim)
# | latest       |  2024-10-22T14:30:00.000000+00:00       |
# ----------------------------------------------------------
```

#### Passo 5: Identificar a Versão Boa

```bash
# A tag é o SHA do commit do GitHub
# Você pode confirmar no GitHub:
# https://github.com/SEU-USUARIO/unifaat-devops-portfolio/commits/main

# Definir a versão boa (substitua pelo SHA correto)
GOOD_VERSION="abc1234def"
```

#### Passo 6: Executar Rollback (Estratégia Recreate)

```bash
# 1. Parar container atual
echo "🛑 Parando container atual..."
docker stop technova-api

# 2. Remover container antigo
echo "🗑️ Removendo container..."
docker rm technova-api

# 3. Puxar imagem da versão boa
echo "📥 Baixando versão anterior ($GOOD_VERSION)..."
docker pull $ECR_REGISTRY/$ECR_REPOSITORY:$GOOD_VERSION

# 4. Iniciar novo container com versão anterior
echo "🚀 Iniciando versão anterior..."
docker run -d \
  --name technova-api \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e GITHUB_SHA=$GOOD_VERSION \
  $ECR_REGISTRY/$ECR_REPOSITORY:$GOOD_VERSION

# 5. Aguardar container iniciar
echo "⏳ Aguardando container iniciar..."
sleep 5

# 6. Verificar se está rodando
docker ps | grep technova-api
```

#### Passo 7: Validar Health Check

```bash
# Testar health endpoint
curl http://localhost:3000/health

# Output esperado:
# {"status":"ok","timestamp":"2024-10-22T15:00:00.000Z","version":"1.0.0"}

# Testar endpoint de negócio
curl http://localhost:3000/api/orders

# Verificar logs (últimas 50 linhas)
docker logs technova-api --tail 50
```

#### Passo 8: Monitorar por 5 Minutos

```bash
# Monitorar logs em tempo real
docker logs -f technova-api

# Em outro terminal SSH, fazer requisições contínuas
watch -n 2 'curl -s http://localhost:3000/health | jq .'

# Verificar uso de recursos
docker stats technova-api
```

### ⚠️ Atenção
- **Este rollback é temporário**
- Git ainda aponta para versão ruim
- Próximo push para `main` vai fazer redeploy da versão ruim
- **Você DEVE fazer git revert depois** para corrigir permanentemente

---

## Método 3: Rollback de Infraestrutura Terraform
### ✅ Quando Usar
- Mudança de infraestrutura causou problema
- Security group bloqueou acesso
- EC2 não inicia
- VPC/Subnet incorreto

### 🕐 Tempo Estimado
10-15 minutos

### 📝 Procedimento

#### Opção A: Git Revert (Recomendado)

```bash
# 1. Identificar commit que mudou Terraform
git log --oneline --all -- aula-10/terraform/

# Exemplo:
# xyz9876 fix: ajusta security group
# abc1234 feat: adiciona RDS

# 2. Reverter commit problemático
git revert xyz9876

# 3. Push
git push origin main

# 4. Workflow terraform-apply.yml vai rodar automaticamente
# 5. Infraestrutura volta ao estado anterior
```

#### Opção B: Rollback Manual do State

⚠️ **USO AVANÇADO - Cuidado!**

```bash
# 1. Ir para diretório Terraform
cd aula-10/terraform/

# 2. Verificar se existe backup do state
ls -la | grep tfstate

# Arquivos possíveis:
# terraform.tfstate          ← State atual
# terraform.tfstate.backup   ← Backup automático

# 3. Restaurar backup (SE EXISTIR)
cp terraform.tfstate.backup terraform.tfstate

# 4. Re-inicializar
terraform init

# 5. Verificar o que vai mudar
terraform plan

# 6. Aplicar state anterior
terraform apply -auto-approve

# 7. Verificar recursos
terraform show
```

#### Opção C: Destruir e Recriar (Último Recurso)

```bash
# ⚠️ ATENÇÃO: ISTO VAI DESTRUIR TUDO

# 1. Fazer checkout do commit bom
git checkout abc1234 -- aula-10/terraform/

# 2. Destruir infraestrutura problemática
cd aula-10/terraform/
terraform destroy -auto-approve

# 3. Recriar com código bom
terraform init
terraform apply -auto-approve

# 4. Commitar o fix
git add .
git commit -m "fix: restaura infraestrutura funcional"
git push origin main
```

---

## Troubleshooting Comum

### Problema 1: Login no ECR Falha

**Erro**:
```
Error response from daemon: Get "https://123456789.dkr.ecr.us-east-1.amazonaws.com/v2/": 
no basic auth credentials
```

**Causa**: Não fez login no ECR antes do `docker pull`

**Solução**:
```bash
# Sempre fazer login antes de puxar imagem
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
```

---

### Problema 2: Credenciais AWS Expiradas

**Erro**:
```
An error occurred (ExpiredToken) when calling the GetAuthorizationToken operation: 
The security token included in the request is expired
```

**Causa**: Sessão do Learner Lab expirou (dura 3 horas)

**Solução**:
```bash
# 1. Voltar ao AWS Academy
# 2. Clicar em "Start Lab"
# 3. Clicar em "AWS Details"
# 4. Copiar novas credenciais

# 5. Atualizar GitHub Secrets:
# GitHub → Settings → Secrets → Actions
# Atualizar:
#  - AWS_ACCESS_KEY_ID
#  - AWS_SECRET_ACCESS_KEY
#  - AWS_SESSION_TOKEN

# 6. Na EC2, reconfigurar:
export AWS_ACCESS_KEY_ID="NOVA_KEY"
export AWS_SECRET_ACCESS_KEY="NOVA_SECRET"
export AWS_SESSION_TOKEN="NOVO_TOKEN"
```

---

### Problema 3: Imagem Não Existe no ECR

**Erro**:
```
Error response from daemon: manifest for 123456789.dkr.ecr.us-east-1.amazonaws.com/
technova-api:abc1234 not found
```

**Causa**: Tag não existe no ECR ou foi deletada pela lifecycle policy

**Solução**:
```bash
# Listar todas as tags disponíveis
aws ecr list-images \
  --repository-name technova-api \
  --region us-east-1

# Se não houver versão boa:
# 1. Fazer git revert para código bom
# 2. Aguardar pipeline fazer novo build
# 3. Novo deploy vai ter versão funcional
```

---

### Problema 4: Container Não Inicia

**Erro**:
```
docker: Error response from daemon: driver failed programming external connectivity 
on endpoint technova-api: Bind for 0.0.0.0:3000 failed: port is already allocated.
```

**Causa**: Porta 3000 já está em uso

**Solução**:
```bash
# Verificar quem está usando a porta
sudo lsof -i :3000

# Parar processo usando a porta
docker stop $(docker ps -q --filter "publish=3000")

# Ou matar processo (se não for Docker)
sudo kill -9 <PID>

# Tentar rodar novamente
docker run -d --name technova-api -p 3000:3000 ...
```

---

### Problema 5: Health Check Falha Após Rollback

**Sintoma**:
```bash
curl http://localhost:3000/health
# curl: (7) Failed to connect to localhost port 3000: Connection refused
```

**Causa**: Container parou ou não iniciou corretamente

**Diagnóstico**:
```bash
# 1. Verificar se container está rodando
docker ps -a | grep technova-api

# Se status for "Exited":
# 2. Ver logs de erro
docker logs technova-api

# 3. Ver motivo da parada
docker inspect technova-api --format='{{.State.Status}}: {{.State.Error}}'
```

**Soluções possíveis**:
```bash
# A) Remover e rodar novamente
docker rm technova-api
docker run -d --name technova-api -p 3000:3000 ...

# B) Se erro for de permissão:
docker run -d --name technova-api -p 3000:3000 --user node ...

# C) Se erro for de variável de ambiente:
docker run -d \
  --name technova-api \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e PORT=3000 \
  ...
```

---

## Checklist Pós-Rollback

Após executar rollback (qualquer método), validar:

### ✅ Validação Técnica

```bash
# 1. Health endpoint responde
curl http://EC2-IP:3000/health
# ✅ Deve retornar: {"status":"ok",...}

# 2. Endpoints de negócio funcionam
curl http://EC2-IP:3000/api/orders
# ✅ Deve retornar array de pedidos

# 3. Container está rodando
docker ps | grep technova-api
# ✅ Status: Up X seconds

# 4. Logs não mostram erros
docker logs technova-api --tail 100 | grep -i error
# ✅ Sem erros críticos

# 5. Uso de recursos normal
docker stats technova-api --no-stream
# ✅ CPU < 50%, MEM < 200MB
```

### 📋 Checklist Administrativa

- [ ] **Notificar time sobre rollback**
  - Slack/Discord: "⚠️ Rollback executado. Versão anterior restaurada."
  
- [ ] **Documentar incidente**
  - Criar issue no GitHub
  - Título: `[INCIDENT] Rollback executado - <data>`
  - Descrever: o que aconteceu, por que, ação tomada
  
- [ ] **Investigar causa raiz**
  - Por que o problema não foi detectado nos testes?
  - Que teste adicionar para prevenir recorrência?
  
- [ ] **Atualizar este runbook**
  - Se encontrou problema não documentado, adicione aqui
  
- [ ] **Se foi rollback manual (Método 2): fazer git revert**
  - Rollback manual é temporário
  - Git deve ser corrigido para evitar redeploy da versão ruim
  
- [ ] **Validar com usuários/stakeholders**
  - Aplicação está funcionando para eles?
  
- [ ] **Monitorar por 30 minutos**
  - Acompanhar logs em tempo real
  - Verificar se problema não volta

---

## Contatos de Emergência

| Situação | Contato | Ação |
|----------|---------|------|
| **Rollback não funciona** | Tech Lead | Escalar problema |
| **Credenciais AWS expiradas** | AWS Lab | Renovar sessão |
| **GitHub Actions travado** | DevOps | Restartar workflow |
| **Infraestrutura corrompida** | Arquiteto | Avaliação técnica |

---

## Logs e Monitoramento

### Onde Encontrar Logs

```bash
# 1. Logs da aplicação (EC2)
ssh ec2-user@EC2-IP
docker logs -f technova-api

# 2. Logs do workflow (GitHub)
https://github.com/SEU-USUARIO/unifaat-devops-portfolio/actions

# 3. Logs do EC2 User Data
ssh ec2-user@EC2-IP
sudo cat /var/log/cloud-init-output.log

# 4. Logs do Docker daemon
ssh ec2-user@EC2-IP
sudo journalctl -u docker.service -n 100
```

### Comandos Úteis de Monitoramento

```bash
# Ver todos os containers (inclusive parados)
docker ps -a

# Ver uso de recursos em tempo real
docker stats

# Ver eventos recentes do Docker
docker events --since 1h

# Ver imagens locais
docker images

# Ver espaço em disco
df -h

# Ver processos rodando
ps aux | grep node
```

---

## Histórico de Rollbacks

**Formato**: Mantenha este registro atualizado

| Data | Método | Versão Ruim | Versão Boa | Causa | Quem Executou |
|------|--------|-------------|------------|-------|---------------|
| 2024-10-22 | Git Revert | def5678 | abc1234 | Bug validação email | @username |
| _exemplo_ | _Manual Docker_ | _xyz9876_ | _abc1234_ | _Timeout na API_ | _@devops_ |

---

**Última Atualização**: Outubro 2024  
**Responsável**: Time DevOps TechNova  
**Versão**: 1.0
