# Aula 03 — IAM com Terraform: Estrutura de Identidade e Acesso para a TechNova

**Aluno:** Felipe Damasceno  
**RA:** 6325128  
**Disciplina:** DevOps — UniFAAT 2026-2  
**Aula:** 03  

---

## Visão Geral

Este módulo Terraform provisiona toda a camada de **Identity and Access Management (IAM)** da empresa fictícia TechNova na AWS, seguindo rigorosamente o princípio de **menor privilégio**: cada identidade recebe apenas as permissões mínimas necessárias para exercer sua função.

---

## Estrutura de Arquivos

```
aula-03/
├── providers.tf              # Provider AWS (hashicorp/aws ~> 5.0, us-east-1)
├── variables.tf              # Variáveis reutilizáveis (project_name, environment, aluno…)
├── main.tf                   # IAM Users, Groups e Memberships
├── policies.tf               # Custom policies (4) + attachments
├── roles.tf                  # Service Role EC2 + Instance Profile
├── outputs.tf                # ARNs e nomes dos recursos provisionados
├── terraform-plan-output.txt # Evidência do terraform plan
├── .gitignore                # Exclusão de state, lock e tfvars
└── README.md                 # Este arquivo
```

---

## Design das Identidades

### Groups

| Group | Propósito |
|---|---|
| `SEURA-technova-developers` | Desenvolvedores com acesso de leitura ao S3 |
| `SEURA-technova-platform-eng` | Engenheiros com gerenciamento completo de EC2 + S3 |

### Users e seus Groups

| User | Group(s) | Observação |
|---|---|---|
| `SEURA-juliana-dev` | developers | Acesso S3 read-only via group |
| `SEURA-rafael-platform` | developers + platform-eng | Acesso combinado: herda permissões dos dois groups |
| `SEURA-lucas-intern` | developers | Policy inline restritiva limita ainda mais o acesso herdado |

### Lógica de Avaliação de Políticas

A AWS avalia as políticas IAM na seguinte ordem: um **Deny explícito** sempre vence sobre qualquer **Allow**. Para o `lucas-intern`, isso significa:

1. Herda `s3:GetObject` e `s3:ListBucket` do grupo `developers` (via `s3-read`)
2. Herda o `deny-destructive` do grupo (proteção contra Delete*/Terminate*)
3. A policy inline `lucas-intern-restricted` adiciona um `Deny` explícito a escritas e a EC2/IAM — garantindo que, mesmo que no futuro o grupo receba novas permissões, o estagiário permanece limitado a leitura básica

---

## Design das Policies

### 1. `SEURA-technova-s3-read` → Group: developers

Permite somente leitura em buckets com prefixo `technova-*`:

- `s3:ListBucket`, `s3:GetBucketLocation` no recurso `arn:aws:s3:::technova-*`
- `s3:GetObject`, `s3:GetObjectVersion`, `s3:GetObjectTagging` em `arn:aws:s3:::technova-*/*`

### 2. `SEURA-technova-ec2-s3-full` → Group: platform-eng

Combina gerenciamento de EC2 com acesso completo ao S3:

- **EC2 Describe** (sem restrição de recurso — necessário para listar instâncias)
- **EC2 Start/Stop/Reboot** com `Condition: ec2:ResourceTag/Project = TechNova` — engenheiros só podem operar instâncias que pertençam ao projeto
- **S3 List + Read/Write** em `technova-*`

### 3. `SEURA-technova-deny-destructive` → Group: developers

Guardrail de proteção: **Deny explícito** sobre `Delete*` e `Terminate*` nos serviços S3, EC2 e IAM. Como Deny sempre vence Allow, nenhum usuário do grupo developers consegue executar operações destrutivas, mesmo que receba um Allow de outra fonte.

### 4. `SEURA-technova-lucas-intern-restricted` (inline no user)

Policy diretamente no usuário `lucas-intern`: restringe ao mínimo (`ListBucket` + `GetObject`) e nega explicitamente qualquer escrita em S3 e qualquer ação em EC2/IAM — camada extra de defesa para o estagiário.

---

## Design da Service Role (EC2 → S3)

```
EC2 Instance
    │
    └─► assume role: SEURA-technova-ec2-role
              │
              ├─► Trust Policy: Principal = ec2.amazonaws.com
              │
              └─► Permissions: Read/Write em arn:aws:s3:::technova-app-data-*
                      ├── s3:ListBucket / GetBucketLocation
                      ├── s3:GetObject / GetObjectVersion
                      ├── s3:PutObject / PutObjectTagging
                      ├── s3:DeleteObject
                      └── s3:AbortMultipartUpload
```

O **Instance Profile** `SEURA-technova-ec2-profile` é o mecanismo que associa a role à instância EC2 no momento do launch — sem ele, a instância não consegue assumir a role automaticamente.

---

## Tags em Todos os Recursos

Todos os recursos usam `default_tags` configurado no provider, garantindo consistência:

```hcl
tags = {
  Project    = "TechNova"
  ManagedBy  = "Terraform"
  Aluno      = "Felipe Damasceno"
  RA         = "6325128"
  Disciplina = "DevOps - UniFAAT 2026-2"
  Aula       = "03"
}
```

---

## Como Executar

```bash
# Pré-requisito: credenciais AWS configuradas (aws configure ou variáveis de ambiente)

cd aula-03/

# Inicializa o provider e baixa plugins
terraform init

# Valida a sintaxe e a lógica dos arquivos
terraform validate

# Visualiza os recursos que serão criados (sem aplicar)
terraform plan -out=tfplan

# Salva o output para evidência
terraform plan > terraform-plan-output.txt

# Aplica a infraestrutura
terraform apply tfplan

# Para destruir todos os recursos criados
terraform destroy
```

---

## Outputs Disponíveis

Após o `terraform apply`, os seguintes valores são expostos:

| Output | Descrição |
|---|---|
| `all_user_arns` | Mapa com ARNs dos 3 usuários |
| `group_developers_arn` | ARN do grupo developers |
| `group_platform_eng_arn` | ARN do grupo platform-eng |
| `policy_s3_read_arn` | ARN da policy s3-read |
| `policy_ec2_s3_full_arn` | ARN da policy ec2-s3-full |
| `policy_deny_destructive_arn` | ARN da policy deny-destructive |
| `ec2_role_arn` | ARN da service role EC2 |
| `ec2_instance_profile_name` | Nome do instance profile (usado no launch de instâncias) |

---

## Conceitos-chave Aprendidos

- **Princípio do menor privilégio:** conceder somente as permissões mínimas necessárias para cada função, reduzindo a superfície de ataque.
- **Deny explícito:** em IAM, um `Effect: Deny` sempre sobrepõe qualquer `Effect: Allow`, independente da origem da política.
- **Resource-level conditions:** usar `Condition` nas políticas (como `ec2:ResourceTag`) permite restringir ações a subconjuntos de recursos sem criar políticas separadas.
- **Service Role + Trust Policy:** o mecanismo que permite que serviços AWS (como EC2) assumam roles sem necessidade de credenciais estáticas — base da segurança em workloads cloud-native.
- **Instance Profile:** wrapper obrigatório para associar uma IAM Role a uma instância EC2.
- **Infraestrutura como Código (IaC):** toda a configuração IAM versionada em Terraform, auditável via Git e reproduzível em qualquer conta AWS.
