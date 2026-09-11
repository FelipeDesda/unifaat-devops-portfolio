# Aula 05 — RDS e Remote State

**TechNova Infrastructure · Unifaat DevOps**

Infraestrutura completa provisionada com Terraform incluindo rede (VPC), banco de dados gerenciado (RDS PostgreSQL), servidor de aplicação (EC2) e remote state protegido (S3 + DynamoDB).

---

## Arquitetura

```
Internet
    │
    ▼
[Internet Gateway]
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  VPC  10.0.0.0/16                                   │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │  Subnet Pública  10.0.1.0/24  (us-east-1a)  │   │
│  │                                              │   │
│  │   [EC2 t2.micro]  ◄── SSH :22 / API :3000   │   │
│  └──────────────────────┬───────────────────────┘   │
│                         │ PostgreSQL :5432           │
│  ┌──────────────────────▼───────────────────────┐   │
│  │  Subnet Privada 1  10.0.10.0/24 (us-east-1a) │   │
│  │  Subnet Privada 2  10.0.11.0/24 (us-east-1b) │   │
│  │                                              │   │
│  │   [RDS PostgreSQL 15]  (db.t3.micro)         │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

Remote State:
  S3 Bucket   → technova-tfstate-unifaat
  DynamoDB    → technova-tfstate-lock
```

---

## Estrutura de Arquivos

```
aula-05/
├── bootstrap/                   # Módulo de bootstrap — cria o backend remoto
│   ├── main.tf                  #   Provider AWS (state local — sem backend)
│   ├── s3.tf                    #   Bucket S3 com versionamento, AES-256 e block public access
│   ├── dynamodb.tf              #   Tabela DynamoDB para locking do state
│   ├── outputs.tf               #   Outputs: bucket name, ARN e lock table name
│   └── variables.tf             #   Variáveis: aws_region, project_name, tfstate_bucket_name
│
├── backend.tf                   # Configuração do remote state (S3 + DynamoDB)
├── providers.tf                 # Provider AWS + versões + default_tags
├── variables.tf                 # Todas as variáveis (sensíveis marcadas)
├── terraform.tfvars.example     # Template de variáveis (commitar)
├── vpc.tf                       # VPC, subnets, IGW, route tables
├── security_groups.tf           # SGs para EC2 e RDS
├── rds.tf                       # DB Subnet Group + instância RDS PostgreSQL
├── ec2.tf                       # Instância EC2 com user_data
├── outputs.tf                   # Outputs úteis (endpoint, IPs, comandos)
├── .gitignore                   # Exclui .terraform/, *.tfstate, *.pem, tfvars
└── README.md                    # Este arquivo
```

---

## Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado (`aws configure`)
- Key Pair criado na conta AWS (para acesso SSH ao EC2)
- Permissões IAM: EC2, RDS, VPC, S3, DynamoDB

---

## Passo 1 — Criar a Infraestrutura de Remote State (Bootstrap)

> O bucket S3 e a tabela DynamoDB precisam existir **antes** de rodar o `terraform init` com o backend configurado.
> O módulo `bootstrap/` provisiona tudo isso via Terraform, com state local.

```bash
cd bootstrap/

# Inicializa o módulo (state local — sem backend remoto ainda)
terraform init

# Verifica o que será criado
terraform plan

# Cria o bucket S3 e a tabela DynamoDB
terraform apply
```

O módulo cria automaticamente:

| Recurso | Configuração |
|---------|-------------|
| **S3 Bucket** | Versionamento habilitado, SSE-AES256, block public access completo |
| **Bucket Policy** | Nega HTTP puro e uploads sem encriptação |
| **DynamoDB Table** | `technova-tfstate-lock`, chave `LockID`, billing `PAY_PER_REQUEST` |

> **Atenção:** O state do `bootstrap/` fica local (`bootstrap/terraform.tfstate`). Guarde esse arquivo em segurança ou commite-o — ele é o único registro dos recursos de backend que foram criados.

Após o `apply`, anote os outputs — eles são usados na configuração do `backend.tf`:

```bash
terraform output
# tfstate_bucket_name     = "technova-tfstate-unifaat"
# tfstate_bucket_arn      = "arn:aws:s3:::technova-tfstate-unifaat"
# tfstate_lock_table_name = "technova-tfstate-lock"
```

```bash
# Voltar para o diretório principal
cd ..
```

---

## Passo 2 — Configurar Variáveis

```bash
# Copie o template e preencha com seus valores reais
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com:
- `key_pair_name` — nome do seu Key Pair na AWS
- `db_username` — usuário do banco (ex: `technova_admin`)
- `db_password` — senha forte sem os caracteres `/ @ " ' ` ou espaços (restrição do RDS PostgreSQL)

> **Atenção:** `terraform.tfvars` está no `.gitignore`. **Nunca commite** credenciais.

---

## Passo 3 — Inicializar e Aplicar

```bash
# Inicializa com o backend S3 configurado
terraform init

# Verifica o plano de execução
terraform plan

# Aplica a infraestrutura (~10–15 min por causa do RDS)
terraform apply
```

---

## Passo 4 — Verificar o Remote State no S3

```bash
# Lista o state file no bucket
aws s3 ls s3://technova-tfstate-unifaat/aula-05/

# Saída esperada:
# 2026-09-11 14:30:00    XXXXX terraform.tfstate
```

---

## Passo 5 — Conectar ao EC2 e Testar o RDS

```bash
# 1. Obter o IP público do EC2 via output
terraform output ec2_public_ip

# 2. Conectar via SSH (substitua pelo nome do seu .pem)
ssh -i minha-chave-aws.pem ec2-user@<EC2_PUBLIC_IP>

# 3. Dentro do EC2 — verificar instalação do psql
psql --version

# 4. Obter o endpoint do RDS
terraform output rds_endpoint

# 5. Conectar ao RDS via psql
psql -h <RDS_ENDPOINT> -U technova_admin -d technova_db -W
# Digite a senha quando solicitado

# 6. Testar dentro do psql
\l          -- lista databases
\conninfo   -- mostra informações da conexão atual
\q          -- sair
```

---

## Outputs Disponíveis

| Output | Descrição |
|--------|-----------|
| `vpc_id` | ID da VPC criada |
| `public_subnet_id` | ID da subnet pública (EC2) |
| `private_subnet_ids` | IDs das subnets privadas (RDS) |
| `ec2_public_ip` | IP público da instância EC2 |
| `ec2_public_dns` | DNS público da instância EC2 |
| `ec2_ssh_command` | Comando SSH pronto para uso |
| `rds_endpoint` | Endpoint de conexão do RDS |
| `rds_port` | Porta do RDS (5432) |
| `rds_db_name` | Nome do banco de dados |
| `rds_connection_string` | String de conexão *(sensitive)* |
| `psql_command` | Comando psql completo *(sensitive)* |
| `tfstate_bucket` | Nome do bucket S3 do state |

Para ver outputs sensíveis:
```bash
terraform output rds_connection_string
terraform output psql_command
```

---

## Evidências — Checklist de Validação

### Remote State
- [ ] `cd bootstrap/ && terraform apply` conclui sem erros
- [ ] `terraform output` exibe bucket name, ARN e lock table name
- [ ] `aws s3 ls s3://technova-tfstate-unifaat/aula-05/` mostra o `terraform.tfstate`
- [ ] `terraform init` (raiz) exibe `Successfully configured the backend "s3"`
- [ ] Versionamento habilitado: `aws s3api get-bucket-versioning --bucket technova-tfstate-unifaat`
- [ ] Block Public Access: `aws s3api get-public-access-block --bucket technova-tfstate-unifaat`
- [ ] Tabela DynamoDB criada: `aws dynamodb describe-table --table-name technova-tfstate-lock`

### VPC e Networking
- [ ] `terraform output vpc_id` retorna um VPC ID válido
- [ ] Console AWS → VPC → mostra 3 subnets (1 pública + 2 privadas em AZs diferentes)
- [ ] Route Table pública tem rota `0.0.0.0/0 → igw-xxxxx`

### RDS PostgreSQL
- [ ] Console AWS → RDS → instância `technova-postgres` com status `available`
- [ ] `publicly_accessible = false` confirmado
- [ ] `storage_encrypted = true` confirmado
- [ ] DB Subnet Group com 2 subnets em AZs diferentes

### EC2 + Conexão
- [ ] SSH funcional: `ssh -i chave.pem ec2-user@<IP>`
- [ ] `psql --version` retorna `psql (PostgreSQL) 15.x`
- [ ] Conexão ao RDS via `psql -h <endpoint> -U technova_admin -d technova_db -W` bem-sucedida

### Segurança
- [ ] SG do RDS permite porta 5432 **apenas** do SG do EC2
- [ ] SG do EC2 permite 22 e 3000
- [ ] `terraform.tfvars` não existe no repositório (`.gitignore` ativo)
- [ ] `*.pem` não commitado

---

## Destruir a Infraestrutura

```bash
# 1. Destruir a infra principal (EC2, RDS, VPC, etc.)
terraform destroy
```

```bash
# 2. Destruir o bootstrap (S3 + DynamoDB) — somente após destruir a infra principal
# ATENÇÃO: os recursos têm prevent_destroy = true; remova-o antes se quiser destruir
cd bootstrap/
terraform destroy
```

> Para forçar a remoção do bucket manualmente (caso ainda haja objetos):
> ```bash
> # Esvaziar todas as versões do bucket (CUIDADO: apaga o state!)
> aws s3 rm s3://technova-tfstate-unifaat --recursive
> aws s3api delete-bucket --bucket technova-tfstate-unifaat
> ```

---

## Decisões de Projeto

| Decisão | Justificativa |
|---------|---------------|
| `multi_az = false` | Ambiente de laboratório — reduz custo |
| `skip_final_snapshot = true` | Lab — sem necessidade de snapshot final |
| `publicly_accessible = false` | Segurança — RDS acessível apenas via EC2 |
| `storage_encrypted = true` | Boas práticas — dados em repouso encriptados |
| `backup_retention_period = 0` | Lab — desabilita backups automáticos para free tier |
| SG RDS → source: SG EC2 | Mais seguro que liberar CIDR da VPC inteira |

---

*TechNova · Unifaat DevOps · Aula 05*
