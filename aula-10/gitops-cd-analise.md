# GitOps e CD Pipeline - Análise Completa
## TechNova - Aula 10

---

## 📋 Sumário
- [1. Fluxo GitOps](#1-fluxo-gitops)
- [2. Autenticação AWS no Learner Lab](#2-autenticação-aws-no-learner-lab)
- [3. Estratégia de Deploy Recreate](#3-estratégia-de-deploy-recreate)
- [4. Continuous Delivery vs Continuous Deployment](#4-continuous-delivery-vs-continuous-deployment)
- [5. Procedimento de Rollback](#5-procedimento-de-rollback)
- [6. Limitações e Melhorias](#6-limitações-e-melhorias)

---

## 1. Fluxo GitOps

### O que é GitOps?

GitOps é uma prática operacional que usa Git como **única fonte da verdade** para infraestrutura e aplicações. Todo o estado desejado do sistema é versionado em Git, e mudanças são aplicadas automaticamente via pipelines.

### Por que Plan no PR e Apply no Merge?

#### **Plan no Pull Request** (terraform-plan.yml)

**Objetivo**: Validar mudanças de infraestrutura **antes** do merge.

**Benefícios**:
- ✅ **Visibilidade**: Desenvolvedores veem o que será criado/modificado/destruído
- ✅ **Revisão em equipe**: Plan vira parte do code review
- ✅ **Prevenção de erros**: Detecta problemas antes de aplicar
- ✅ **Segurança**: Identifica operações perigosas (destroy) antes que aconteçam
- ✅ **Documentação**: O plan fica registrado no PR como evidência

**Funcionamento**:
```yaml
on:
  pull_request:
    branches: [main]
    paths: ['aula-10/terraform/**/*.tf']
```

**Fluxo**:
1. Desenvolvedor cria PR com mudanças em arquivos `.tf`
2. GitHub Actions dispara terraform-plan.yml
3. Workflow executa: `init` → `validate` → `plan`
4. Plan é postado como **comentário no PR**
5. Time revisa o plan junto com o código
6. Se aprovado, PR é mergeado

#### **Apply no Merge para Main** (terraform-apply.yml)

**Objetivo**: Aplicar mudanças automaticamente após aprovação.

**Benefícios**:
- ✅ **Automação**: Elimina execução manual (erro humano)
- ✅ **Consistência**: Sempre usa o mesmo processo
- ✅ **Rastreabilidade**: Cada apply está vinculado a um commit
- ✅ **Auditoria**: Logs completos no GitHub Actions
- ✅ **Rollback facilitado**: Basta reverter o commit

**Funcionamento**:
```yaml
on:
  push:
    branches: [main]
    paths: ['aula-10/terraform/**/*.tf']
```

**Fluxo**:
1. PR é mergeado na branch `main`
2. GitHub Actions dispara terraform-apply.yml
3. Workflow executa: `init` → `apply -auto-approve`
4. Infraestrutura é atualizada automaticamente
5. Outputs são exibidos no job summary

### Vantagens do Fluxo GitOps Completo

| Aspecto | Antes (Manual) | Depois (GitOps) |
|---------|----------------|-----------------|
| **Execução** | Desenvolvedor roda terraform localmente | GitHub Actions roda automaticamente |
| **Aprovação** | Confiança + "tomara que funcione" | Plan revisado no PR |
| **Auditoria** | "Quem mexeu na infra?" | Todo commit é rastreado |
| **Rollback** | Depende do state, pode ser complexo | Git revert + apply automático |
| **Consistência** | Cada dev pode usar versões diferentes | Versão única do Terraform no CI |
| **Segurança** | Credenciais locais podem vazar | Credenciais apenas no GitHub Secrets |

### Proteções Implementadas

✅ **Detecção de Destroy**: Se o plan contém operações de `destroy`, workflow emite alerta no PR  
✅ **Format Check**: `terraform fmt -check` garante formatação consistente  
✅ **Validação**: `terraform validate` roda antes do plan  
✅ **Comentário Único**: Plan atualiza comentário existente (não duplica)  
✅ **Fail Fast**: Se plan falha, workflow falha e PR não pode ser mergeado

---

## 2. Autenticação AWS no Learner Lab

### Contexto do AWS Academy Learner Lab

O **AWS Academy Learner Lab** é um ambiente educacional com limitações de segurança:

❌ Não permite criar **IAM OIDC Identity Provider**  
❌ Não permite criar **IAM Roles** com trust policy para GitHub  
❌ Não permite modificar permissões do Lab User  
✅ Fornece **credenciais temporárias de sessão** (válidas por 3h)

### Como Autenticamos no Lab: Credenciais de Sessão

**GitHub Secrets configurados**:
```
AWS_ACCESS_KEY_ID         # Access Key da sessão
AWS_SECRET_ACCESS_KEY     # Secret Key da sessão
AWS_SESSION_TOKEN         # Session Token (obrigatório!)
```

**Workflow** (terraform-plan.yml e terraform-apply.yml):
```yaml
- name: Configure AWS Credentials (Learner Lab Session)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
    aws-region: us-east-1
```

### ⚠️ Limitações desta Abordagem

| Problema | Impacto |
|----------|---------|
| **Credenciais expiram** | Após 3h, precisa atualizar os secrets manualmente |
| **Secrets no GitHub** | Credenciais ficam armazenadas (mas criptografadas) |
| **Rotação manual** | Não há rotação automática |
| **Menos seguro** | Não usa princípio de least privilege ideal |

### 🏆 Padrão Ideal: OIDC + IAM Role (Produção)

**Por que OIDC é melhor?**

✅ **Sem credenciais estáticas**: GitHub recebe token JWT temporário  
✅ **Least Privilege**: Role tem apenas permissões necessárias  
✅ **Rotação automática**: Tokens duram apenas minutos  
✅ **Auditoria**: CloudTrail registra qual workflow assumiu a role  
✅ **Zero Secrets**: Nenhuma credencial armazenada no GitHub

**Como seria em produção** (não funciona no Lab):

1. **Criar OIDC Provider na AWS**:
```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

2. **Criar Role com Trust Policy para GitHub**:
```hcl
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:USERNAME/REPO:ref:refs/heads/main"
        }
      }
    }]
  })
}
```

3. **Workflow usando OIDC** (versão ideal):
```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions-terraform
    aws-region: us-east-1
    # Sem secrets necessários!
```

### Documentação do Padrão OIDC

**Referências oficiais**:
- [GitHub Actions - OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS - IAM OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials#assuming-a-role)

### Conclusão sobre Autenticação

| Método | Uso | Segurança | Manutenção |
|--------|-----|-----------|------------|
| **Credenciais de sessão (Lab)** | ✅ Funciona no Lab | ⚠️ Média | ❌ Manual |
| **OIDC + Role (Produção)** | ❌ Bloqueado no Lab | ✅ Alta | ✅ Automática |

**Nota importante**: Em ambientes corporativos reais, **sempre use OIDC**. Credenciais estáticas devem ser evitadas.

---

## 3. Estratégia de Deploy: Recreate

### O que é a Estratégia Recreate?

**Recreate** é a estratégia mais simples de deploy:

1. **Stop** → Para a versão antiga
2. **Remove** → Remove o container antigo
3. **Pull** → Baixa a nova imagem
4. **Run** → Inicia novo container

```bash
# Implementação no workflow cd.yml
docker stop technova-api
docker rm technova-api
docker pull $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
docker run -d --name technova-api -p 3000:3000 $FULL_IMAGE
```

### Prós da Estratégia Recreate

| Vantagem | Explicação |
|----------|------------|
| ✅ **Simplicidade** | Fácil de entender e implementar |
| ✅ **Sem complexidade** | Não precisa load balancer ou orquestrador |
| ✅ **Uso de recursos** | Não roda duas versões simultaneamente |
| ✅ **Consistência de estado** | Não há mistura de versões |
| ✅ **Debug facilitado** | Sempre há apenas uma versão rodando |

### Contras da Estratégia Recreate

| Desvantagem | Impacto |
|-------------|---------|
| ❌ **Downtime** | Aplicação fica offline durante o deploy (~10-30s) |
| ❌ **Experiência do usuário** | Usuários recebem erro 502/503 durante deploy |
| ❌ **Não é HA** | Não garante alta disponibilidade |
| ❌ **Rollback com downtime** | Rollback também causa interrupção |

### Quando Usar Recreate?

✅ **Ambientes de desenvolvimento/staging**  
✅ **Aplicações internas com janela de manutenção**  
✅ **Deploys fora do horário comercial**  
✅ **Projetos com poucos usuários**  
✅ **Orçamento limitado** (não precisa de múltiplas instâncias)

❌ **Não usar em produção crítica** (e-commerce, APIs de pagamento, etc.)

### Alternativas à Estratégia Recreate

#### 1. **Rolling Update** (Gradual)
```bash
# Substitui containers gradualmente
# 1. Sobe novo container na porta 3001
# 2. Remove do load balancer a porta 3000
# 3. Para container antigo
# 4. Sobe novo na porta 3000
```
**Prós**: Sem downtime  
**Contras**: Mais complexo, múltiplas versões rodando simultaneamente

#### 2. **Blue-Green Deployment**
```bash
# Mantém duas versões completas
# Blue (atual): porta 3000
# Green (nova): porta 3001
# Troca tráfego do load balancer de Blue para Green
```
**Prós**: Rollback instantâneo, sem downtime  
**Contras**: Dobra uso de recursos

#### 3. **Canary Deployment**
```bash
# Libera nova versão gradualmente
# 5% tráfego → nova versão
# 95% tráfego → versão antiga
# Se OK, aumenta para 100%
```
**Prós**: Detecta problemas antes de afetar todos  
**Contras**: Muito complexo, precisa monitoramento avançado

### Comparação de Estratégias

| Estratégia | Downtime | Complexidade | Recursos | Rollback | Melhor para |
|------------|----------|--------------|----------|----------|-------------|
| **Recreate** | ❌ Sim (~30s) | ✅ Baixa | ✅ Mínimo | ⚠️ Com downtime | Dev/Staging |
| **Rolling** | ✅ Zero | ⚠️ Média | ⚠️ +50% | ✅ Automático | Produção |
| **Blue-Green** | ✅ Zero | ⚠️ Média | ❌ Dobro | ✅ Instantâneo | Alta criticidade |
| **Canary** | ✅ Zero | ❌ Alta | ⚠️ +20% | ✅ Parcial | Grandes escalas |

### Mitigação do Downtime em Recreate

**Técnicas implementadas no workflow**:

1. **Health Check com Retry**:
```yaml
max_attempts=10
while [ $attempt -le $max_attempts ]; do
  if curl -f http://EC2_HOST:3000/health; then
    exit 0
  fi
  sleep 10
done
```

2. **Login no ECR antes do Pull** (evita erro de autenticação):
```bash
aws ecr get-login-password | docker login --username AWS --password-stdin
```

3. **Sleep após docker run** (aguarda inicialização):
```bash
docker run -d ...
sleep 5  # Container tem tempo de iniciar
```

### Conclusão sobre Recreate

✅ **Para este projeto educacional**: Recreate é adequado  
⚠️ **Para produção**: Considerar Rolling Update ou Blue-Green  
📚 **Aprendizado**: Entender trade-offs é mais importante que sempre usar a solução mais complexa

---

## 4. Continuous Delivery vs Continuous Deployment

### Definições

#### **Continuous Delivery (CD - Entrega Contínua)**

> Prática onde código está **sempre pronto para produção**, mas deploy para produção é **manual** (gatilho humano).

```
Commit → Build → Test → Stage → [APROVAÇÃO MANUAL] → Produção
                                      👤 Humano decide
```

#### **Continuous Deployment (CD - Deploy Contínuo)**

> Prática onde código passa por pipeline automatizado e vai **direto para produção sem intervenção humana**.

```
Commit → Build → Test → Stage → Produção (automático)
                                  🤖 Totalmente automatizado
```

### Diferença Fundamental

| Aspecto | Continuous Delivery | Continuous Deployment |
|---------|---------------------|----------------------|
| **Deploy Produção** | Manual (botão/aprovação) | Automático |
| **Quem decide** | Humano | Pipeline |
| **Frequência** | Quando alguém aprovar | Todo commit que passar nos testes |
| **Controle** | Alto | Médio |
| **Velocidade** | Média | Alta |
| **Risco** | Menor (humano revisa) | Maior (tudo automatizado) |

### Exemplos Práticos

#### Continuous Delivery:
```yaml
# Deploy só acontece com aprovação manual
jobs:
  deploy:
    environment:
      name: production
      # GitHub exige aprovação manual aqui
    steps:
      - name: Deploy
        run: kubectl apply -f deployment.yml
```

**Empresas que usam**: Netflix, Amazon, Google (deploys grandes)

#### Continuous Deployment:
```yaml
# Deploy acontece automaticamente se testes passarem
jobs:
  deploy:
    needs: [test, lint]
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy
        run: kubectl apply -f deployment.yml
```

**Empresas que usam**: Facebook, Spotify, Etsy (deploys pequenos frequentes)

### Nosso Projeto: Continuous Delivery

**Por quê?**

1. **Environment Protection Rule**:
```yaml
environment:
  name: production  # GitHub pode exigir aprovação
```

2. **Fluxo**:
```
1. Desenvolvedor faz commit
2. Pipeline roda: lint → test → build → push (ECR)
3. [PAUSA] → Alguém aprova deploy (opcional)
4. Deploy executa na EC2
5. Health check valida
```

3. **Vantagens neste contexto**:
- ✅ Terraform apply já é automático (infra é menos arriscada)
- ✅ Deploy de aplicação pode ter revisão extra
- ✅ Permite deploy fora de horário comercial
- ✅ Adequado para ambiente educacional

### Quando Usar Cada Abordagem?

#### Use **Continuous Delivery** se:
- ✅ Precisa de conformidade regulatória (financeiro, saúde)
- ✅ Deploy tem impacto grande (milhões de usuários)
- ✅ Time não tem confiança total nos testes automatizados
- ✅ Produto tem ciclo de release (deploys semanais)
- ✅ Stakeholders querem controle sobre quando features são liberadas

#### Use **Continuous Deployment** se:
- ✅ Testes automatizados são robustos (>80% coverage)
- ✅ Feature flags permitem desabilitar features em produção
- ✅ Monitoramento detecta problemas rapidamente
- ✅ Rollback é automático e confiável
- ✅ Time tem cultura de ownership e responsabilidade
- ✅ Deploy é de baixo risco (microserviços pequenos)

### Maturidade das Práticas

```
Nível 1: Manual           → Deploy manual quando alguém lembra
Nível 2: Automated Build  → CI roda, mas deploy é manual
Nível 3: Continuous Delivery → Código sempre pronto, deploy manual
Nível 4: Continuous Deployment → Tudo automático
```

**A maioria das empresas está no Nível 3** (Continuous Delivery).

### Feature Flags: O Meio Termo

**Solução híbrida**: Continuous Deployment + Feature Flags

```javascript
// Código vai para produção, mas feature fica desabilitada
if (featureFlags.newCheckout) {
  // Nova versão do checkout
} else {
  // Versão antiga (fallback)
}
```

**Vantagens**:
- ✅ Deploy automático (sem risco)
- ✅ Controle de quando ativar a feature
- ✅ A/B testing
- ✅ Rollback via config (sem redeploy)

**Ferramentas**: LaunchDarkly, Split.io, AWS AppConfig

---

## 5. Procedimento de Rollback

### Cenários que Exigem Rollback

1. ❌ **Health check falha após deploy**
2. ❌ **Bug crítico em produção**
3. ❌ **Performance degradada**
4. ❌ **Erro não detectado em testes**

### Estratégia 1: Rollback via Git Revert (Recomendado)

**Quando usar**: Problema foi introduzido no último commit

#### Passo a Passo:

```bash
# 1. Identificar o commit problemático
git log --oneline -5

# Exemplo de output:
# abc1234 feat: nova feature de checkout
# def5678 fix: corrige bug no login
# ghi9012 docs: atualiza README

# 2. Reverter o commit problemático
git revert abc1234

# 3. Push do revert
git push origin main

# 4. Pipeline vai rodar automaticamente
# - lint → test → build → deploy
# - Aplicação volta para versão anterior
```

#### Vantagens:
✅ Git mantém histórico completo  
✅ Auditável (quem fez rollback e por quê)  
✅ Passa por todo o pipeline (seguro)  
✅ Funciona tanto para código quanto para Terraform

### Estratégia 2: Rollback Manual de Imagem Docker

**Quando usar**: Emergência, precisa ser rápido

#### Passo a Passo:

```bash
# 1. Conectar na EC2
ssh -i vockey.pem ec2-user@<EC2_IP>

# 2. Login no ECR (obrigatório!)
AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# 3. Listar tags disponíveis no ECR
aws ecr describe-images \
  --repository-name technova-api \
  --region us-east-1 \
  --query 'sort_by(imageDetails,& imagePushedAt)[*].[imageTags[0],imagePushedAt]' \
  --output table

# Exemplo de output:
# |  Tag (SHA)  |     Pushed At        |
# |-------------|----------------------|
# | abc1234     | 2024-10-20T10:00:00  | ← versão anterior (boa)
# | def5678     | 2024-10-22T14:30:00  | ← versão atual (ruim)

# 4. Parar container atual
docker stop technova-api
docker rm technova-api

# 5. Puxar versão anterior (IMPORTANTE: fazer login antes!)
OLD_TAG=abc1234  # SHA do commit anterior
docker pull $ECR_REGISTRY/technova-api:$OLD_TAG

# 6. Rodar versão anterior
docker run -d \
  --name technova-api \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=production \
  $ECR_REGISTRY/technova-api:$OLD_TAG

# 7. Verificar health
sleep 5
curl http://localhost:3000/health

# 8. Verificar logs
docker logs technova-api --tail 50
```

#### ⚠️ Problema Comum: Esqueceu o Login no ECR

**Erro**:
```
Error response from daemon: Head "https://123456789.dkr.ecr.us-east-1.amazonaws.com/v2/technova-api/manifests/abc1234": no basic auth credentials
```

**Solução**: Sempre fazer login antes do `docker pull`:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
```

### Estratégia 3: Rollback de Infraestrutura (Terraform)

**Quando usar**: Mudança de infraestrutura causou problema

#### Opção A: Git Revert (Recomendado)
```bash
# 1. Reverter commit do Terraform
git revert <commit-hash-terraform>
git push origin main

# 2. Workflow terraform-apply.yml vai rodar
# 3. Infraestrutura volta ao estado anterior
```

#### Opção B: Rollback Manual do State
```bash
# ⚠️ USAR COM CUIDADO

# 1. Listar versões do state
terraform state list

# 2. Restaurar backup do state (se houver)
cd aula-10/terraform
cp terraform.tfstate.backup terraform.tfstate

# 3. Aplicar state anterior
terraform apply -auto-approve
```

### Estratégia 4: Rollback com GitHub Environments

**Se tiver environment protection configurado:**

1. Acesse: GitHub → Settings → Environments → production
2. Clique em "View deployment"
3. Clique em "Re-run jobs" em um deploy anterior

**Ou via CLI**:
```bash
# Triggerar redeploy de um commit específico
gh workflow run cd.yml --ref main --field sha=abc1234
```

### Checklist de Rollback

```
[ ] 1. Identificar versão estável anterior
[ ] 2. Verificar se credenciais AWS estão válidas
[ ] 3. Fazer login no ECR antes de puxar imagem
[ ] 4. Executar rollback (Git revert OU manual)
[ ] 5. Aguardar health check passar
[ ] 6. Verificar logs da aplicação
[ ] 7. Testar endpoints críticos manualmente
[ ] 8. Notificar time sobre o rollback
[ ] 9. Investigar causa raiz do problema
[ ] 10. Criar issue no GitHub com post-mortem
```

### Monitoramento Pós-Rollback

```bash
# Monitorar logs em tempo real
docker logs -f technova-api

# Verificar health a cada 5 segundos
watch -n 5 curl http://localhost:3000/health

# Verificar uso de recursos
docker stats technova-api

# Verificar se container está rodando
docker ps | grep technova-api
```

### Documentação de Incidentes

**Criar arquivo `docs/incidents/YYYY-MM-DD-rollback.md`**:

```markdown
# Rollback - 2024-10-22

## Incidente
- **Horário**: 14:35 UTC
- **Duração**: 5 minutos
- **Impacto**: API retornando 500 em 30% das requisições

## Ação Tomada
- Rollback manual para SHA abc1234
- Comando: `docker run ... $ECR_REGISTRY/technova-api:abc1234`

## Causa Raiz
- Bug no endpoint /api/orders - não tratava array vazio

## Prevenção
- [ ] Adicionar teste para caso de array vazio
- [ ] Aumentar cobertura de testes para 90%
```

---

## 6. Limitações e Melhorias

### Limitações Atuais

#### 1. **Credenciais AWS Temporárias**
**Problema**: Secrets expiram a cada 3 horas  
**Impacto**: Workflows falham se secrets não forem atualizados  
**Mitigação atual**: Documentação clara de como atualizar

#### 2. **Deploy com Downtime**
**Problema**: Estratégia Recreate causa ~30s de indisponibilidade  
**Impacto**: Usuários recebem erro durante deploy  
**Mitigação atual**: Health check valida sucesso

#### 3. **Sem Backend Remoto do Terraform**
**Problema**: State fica local (comentado no provider.tf)  
**Impacto**: Colaboração é difícil, risco de conflito  
**Mitigação atual**: Comentário documenta backend S3

#### 4. **Sem Monitoramento**
**Problema**: Não há alertas se aplicação cair após deploy  
**Impacto**: Time não sabe se há problema em produção  
**Mitigação atual**: Health check no workflow (apenas no momento do deploy)

#### 5. **Secrets em Claro no GitHub**
**Problema**: EC2 SSH key como secret (mesmo criptografado)  
**Impacto**: Risco se GitHub for comprometido  
**Mitigação atual**: IAM role na EC2 limita danos

#### 6. **Sem Testes de Integração**
**Problema**: Apenas testes unitários  
**Impacto**: Bugs de integração só são detectados em produção  
**Mitigação atual**: Health check após deploy

### Melhorias Recomendadas

#### **Prioridade Alta** 🔴

##### 1. **Implementar Backend S3 para Terraform State**
```hcl
# Descomentar em provider.tf
backend "s3" {
  bucket         = "technova-terraform-state"
  key            = "aula-10/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "technova-terraform-locks"
  encrypt        = true
}
```
**Benefício**: State compartilhado, lock para evitar conflitos

##### 2. **Configurar AWS Systems Manager Session Manager**
```hcl
# Substituir SSH por SSM (sem necessidade de chaves)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```
**Benefício**: Sem chaves SSH, logs de sessão no CloudTrail

##### 3. **Adicionar Cost Estimation com Infracost**
```yaml
# No terraform-plan.yml
- name: Run Infracost
  run: |
    infracost breakdown --path . \
      --format json \
      --out-file /tmp/infracost.json
```
**Benefício**: Saber custo antes de criar recursos

#### **Prioridade Média** 🟡

##### 4. **Migrar de Recreate para Rolling Update**
```yaml
# cd.yml - Nova estratégia
- name: Deploy with Rolling Update
  run: |
    # Sobe novo container em porta diferente
    docker run -d --name technova-api-new -p 3001:3000 $IMAGE
    
    # Health check no novo
    curl -f http://localhost:3001/health
    
    # Atualiza nginx/traefik para usar porta 3001
    # Para container antigo
```
**Benefício**: Zero downtime

##### 5. **Implementar GitHub Environments com Approvers**
```yaml
# cd.yml
environment:
  name: production
  # Configurar em: Settings → Environments → production
  # - Required reviewers: @tech-lead
  # - Wait timer: 5 minutes
```
**Benefício**: Deploy não acontece sem aprovação

##### 6. **Adicionar Smoke Tests Pós-Deploy**
```yaml
- name: Smoke Tests
  run: |
    # Testar endpoints críticos
    curl -f http://$EC2_HOST:3000/api/orders
    curl -f http://$EC2_HOST:3000/api/orders/1
```
**Benefício**: Detectar problemas antes de concluir deploy

##### 7. **Notificações de Deploy (Slack/Discord)**
```yaml
- name: Notify Deploy Success
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "✅ Deploy para produção concluído",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "Deploy *${{ github.sha }}* by @${{ github.actor }}"
            }
          }
        ]
      }
```
**Benefício**: Time sabe quando deploy aconteceu

#### **Prioridade Baixa** 🟢

##### 8. **Docker Multi-Arch Build (ARM + x86)**
```dockerfile
# Suportar arquiteturas diferentes
FROM --platform=$BUILDPLATFORM node:18-alpine
```
**Benefício**: Rodar em Graviton (economia de custo)

##### 9. **Adicionar Workflow de Destroy**
```yaml
# .github/workflows/terraform-destroy.yml
on:
  workflow_dispatch:  # Manual trigger apenas
    inputs:
      confirm:
        description: 'Type "destroy" to confirm'
        required: true
```
**Benefício**: Destruir infra de forma controlada

##### 10. **Terraform Drift Detection**
```yaml
# Workflow diário que detecta mudanças manuais
- name: Detect Drift
  run: |
    terraform plan -detailed-exitcode
    # Exit code 2 = há drift
```
**Benefício**: Detectar mudanças feitas fora do Terraform

### Melhorias de Segurança

#### 1. **Scan de Vulnerabilidades**
```yaml
# cd.yml
- name: Trivy Scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.ECR_REGISTRY }}/technova-api:${{ env.IMAGE_TAG }}
    severity: 'CRITICAL,HIGH'
```

#### 2. **SAST (Static Application Security Testing)**
```yaml
- name: CodeQL Analysis
  uses: github/codeql-action/analyze@v2
```

#### 3. **Secrets Scanning**
```yaml
- name: TruffleHog Scan
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
```

### Melhorias de Observabilidade

#### 1. **Logs Centralizados (CloudWatch)**
```javascript
// server.js
const winston = require('winston');
const CloudWatchTransport = require('winston-cloudwatch');

logger.add(new CloudWatchTransport({
  logGroupName: '/ecs/technova-api',
  logStreamName: process.env.GITHUB_SHA
}));
```

#### 2. **Métricas (Prometheus)**
```javascript
const promClient = require('prom-client');
const register = new promClient.Registry();

app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(register.metrics());
});
```

#### 3. **Tracing (AWS X-Ray)**
```javascript
const AWSXRay = require('aws-xray-sdk');
const app = express();
app.use(AWSXRay.express.openSegment('TechNova'));
// ... routes
app.use(AWSXRay.express.closeSegment());
```

---

## Conclusão

Este projeto implementa um fluxo GitOps completo com:
- ✅ Terraform automatizado (plan no PR, apply no merge)
- ✅ CD Pipeline com health check
- ✅ Deploy automatizado (estratégia Recreate)
- ✅ Documentação de rollback
- ✅ Análise de trade-offs

**Principais aprendizados**:
1. GitOps traz **visibilidade e auditoria** para infra
2. Credenciais de sessão funcionam no Lab, mas **OIDC é o ideal**
3. Recreate é simples mas tem **downtime aceitável** para dev/staging
4. Continuous Delivery dá **controle extra** sobre deploys
5. Rollback precisa ser **testado e documentado**

**Para produção, implementar**:
- [ ] OIDC em vez de credenciais estáticas
- [ ] Rolling Update em vez de Recreate
- [ ] Monitoramento com alertas
- [ ] Backend S3 + DynamoDB para Terraform State
- [ ] Secrets management (AWS Secrets Manager)
- [ ] Testes de integração automatizados

---

**Autor**: [Seu Nome]  
**Data**: Outubro 2024  
**Projeto**: TechNova - DevOps Portfolio - Aula 10
