# Infraestrutura TechNova — Aula 04

Infraestrutura Multi-AZ na AWS provisionada com Terraform para o laboratório da Aula 04 da disciplina de DevOps — UNIFAAT.

---

## Diagrama da Arquitetura

```
                          ┌─────────────────────────────────────────────────────────────────┐
                          │                        AWS — us-east-1                           │
                          │                                                                   │
                          │   ┌─────────────────────────────────────────────────────────┐   │
                          │   │                  VPC: technova-vpc                       │   │
                          │   │                   10.0.0.0/16                            │   │
                          │   │                                                           │   │
                          │   │   ┌────────────────────┐   ┌────────────────────────┐   │   │
                          │   │   │   AZ: us-east-1a   │   │    AZ: us-east-1b      │   │   │
                          │   │   │                    │   │                        │   │   │
                          │   │   │  ┌──────────────┐  │   │  ┌──────────────────┐  │   │   │
                          │   │   │  │  Subnet       │  │   │  │  Subnet          │  │   │   │
                          │   │   │  │  Pública 1    │  │   │  │  Pública 2       │  │   │   │
                          │   │   │  │ 10.0.1.0/24   │  │   │  │ 10.0.3.0/24      │  │   │   │
                          │   │   │  │               │  │   │  │                  │  │   │   │
                          │   │   │  │  ┌─────────┐  │  │   │  │                  │  │   │   │
                          │   │   │  │  │  EC2    │  │  │   │  │  (Load Balancer  │  │   │   │
                          │   │   │  │  │  API    │  │  │   │  │   futuro)        │  │   │   │
                          │   │   │  │  │ :3000   │  │  │   │  │                  │  │   │   │
                          │   │   │  │  └─────────┘  │  │   │  └──────────────────┘  │   │   │
                          │   │   │  └──────────────┘  │   │                        │   │   │
                          │   │   │                    │   │                        │   │   │
                          │   │   │  ┌──────────────┐  │   │  ┌──────────────────┐  │   │   │
                          │   │   │  │  Subnet       │  │   │  │  Subnet          │  │   │   │
                          │   │   │  │  Privada 1    │  │   │  │  Privada 2       │  │   │   │
                          │   │   │  │ 10.0.2.0/24   │  │   │  │ 10.0.4.0/24      │  │   │   │
                          │   │   │  │  (DB futuro)  │  │   │  │  (DB futuro)     │  │   │   │
                          │   │   │  └──────────────┘  │   │  └──────────────────┘  │   │   │
                          │   │   └────────────────────┘   └────────────────────────┘   │   │
                          │   │                                                           │   │
                          │   │          ┌──────────────────────────┐                    │   │
                          │   │          │   Route Table Pública    │                    │   │
                          │   │          │   0.0.0.0/0 → IGW        │                    │   │
                          │   │          └────────────┬─────────────┘                    │   │
                          │   │                       │                                   │   │
                          │   │          ┌────────────▼─────────────┐                    │   │
                          │   │          │   Internet Gateway (IGW) │                    │   │
                          │   └──────────┤        technova-igw      ├────────────────────┘   │
                          │             └────────────┬──────────────┘                        │
                          └──────────────────────────┼──────────────────────────────────────┘
                                                     │
                                               [ Internet ]
                                             curl :3000 / SSH
```

**Fluxo de tráfego:**
- Internet → IGW → Route Table Pública → Subnet Pública → EC2 (porta 22 / 3000)
- Subnets privadas não possuem rota para internet (isolamento para banco de dados futuro)

---

## Como Usar

### Pré-requisitos

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5.0 | `brew install terraform` / `.exe` no Windows |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | >= 2.0 | `brew install awscli` |
| Credenciais AWS | — | AWS Academy Lab / `aws configure` |

> **AWS Academy:** copie as credenciais do painel **AWS Details → AWS CLI** e cole em `~/.aws/credentials`.

### 1. Configurar variáveis

Edite o arquivo `terraform.tfvars` e substitua `SEU-RA-AQUI` pelo seu RA:

```hcl
owner_ra = "123456"
```

### 2. Inicializar o Terraform

```bash
terraform init
```

### 3. Revisar o plano

```bash
terraform plan
# Para salvar como evidência:
terraform plan > evidencia-plan.txt
```

### 4. Aplicar a infraestrutura

```bash
terraform apply
# Confirme digitando: yes
```

Aguarde ~3 minutos para a instância EC2 concluir o User Data (instalação do Node.js e inicialização da API).

---

## Como Testar

### Testar a API via curl

```bash
# Substitua <IP_PUBLICO> pelo valor do output ec2_public_ip
curl http://<IP_PUBLICO>:3000
curl http://<IP_PUBLICO>:3000/health
```

Ou use diretamente o output do Terraform:

```bash
API_URL=$(terraform output -raw api_url)
curl $API_URL
curl $API_URL/health
```

Para salvar como evidência:

```bash
curl http://<IP_PUBLICO>:3000       > evidencia-api.json
curl http://<IP_PUBLICO>:3000/health >> evidencia-api.json
```

### Conectar via SSH

```bash
# O comando exato é exibido no output ssh_command
ssh -i ~/.ssh/technova-key.pem ec2-user@<IP_PUBLICO>

# Verificar versões e identidade IAM:
ssh -i ~/.ssh/technova-key.pem ec2-user@<IP_PUBLICO> \
  "node --version && aws sts get-caller-identity" > evidencia-ssh.txt
```

### Verificar status da API na instância

```bash
ssh -i ~/.ssh/technova-key.pem ec2-user@<IP_PUBLICO> \
  "sudo systemctl status technova-api"
```

---

## Como Destruir

> **Importante:** sempre destrua os recursos após o lab para evitar cobranças!

```bash
terraform destroy
# Confirme digitando: yes
```

---

## Decisões Técnicas

### Por que Multi-AZ?

Distribuir os recursos em duas Availability Zones (`us-east-1a` e `us-east-1b`) garante **alta disponibilidade**: se uma AZ sofrer falha de hardware ou energia, os recursos na outra continuam operando. Essa é a base para qualquer arquitetura de produção na AWS.

### Por que separar subnets públicas e privadas?

O princípio de **menor superfície de ataque** dita que apenas os recursos que precisam ser acessados pela internet devem ficar em subnets públicas. Bancos de dados, filas e serviços internos devem ficar em subnets privadas — sem rota para a internet, mesmo que uma credencial vaze, o atacante não consegue alcançar o banco diretamente. As subnets privadas `10.0.2.0/24` e `10.0.4.0/24` estão prontas para receber um RDS no futuro.

### Por que usar um serviço systemd para a API?

O `systemd` garante que a API seja reiniciada automaticamente em caso de crash (`Restart=on-failure`) e que inicie junto com o sistema após um reboot. É mais robusto que simplesmente chamar `node index.js &` no User Data.

### Por que gerar o Key Pair via Terraform?

Gerar a chave RSA com o provider `tls` e salvá-la com `local_sensitive_file` mantém tudo no código — a chave é criada, registrada na AWS e salva localmente em uma única execução de `terraform apply`, sem passo manual.

### Por que usar `default_tags` no provider?

Centralizar as tags `Project`, `Environment`, `ManagedBy` e `Owner` no bloco `provider` garante que **todos** os recursos recebam essas tags automaticamente, sem necessidade de repeti-las em cada resource. Tags individuais como `Name` são adicionadas por recurso.

---

## Recursos Criados

| Recurso Terraform | Nome AWS | Função |
|---|---|---|
| `aws_vpc.main` | `technova-vpc` | Rede isolada para toda a infraestrutura |
| `aws_subnet.public[0]` | `technova-subnet-public-1` | Subnet pública na AZ us-east-1a (EC2) |
| `aws_subnet.public[1]` | `technova-subnet-public-2` | Subnet pública na AZ us-east-1b (LB futuro) |
| `aws_subnet.private[0]` | `technova-subnet-private-1` | Subnet privada na AZ us-east-1a (DB futuro) |
| `aws_subnet.private[1]` | `technova-subnet-private-2` | Subnet privada na AZ us-east-1b (DB futuro) |
| `aws_internet_gateway.main` | `technova-igw` | Porta de saída para a internet |
| `aws_route_table.public` | `technova-rt-public` | Roteia tráfego das subnets públicas para o IGW |
| `aws_route_table_association.public[*]` | — | Liga as subnets públicas à route table pública |
| `aws_security_group.api` | `technova-sg-api` | Permite SSH (22) e API (3000) de qualquer IP |
| `aws_security_group.db` | `technova-sg-db` | Permite PostgreSQL (5432) apenas de dentro da VPC |
| `aws_iam_role.ec2_role` | `technova-ec2-role` | Permite que o EC2 assuma permissões AWS |
| `aws_iam_role_policy_attachment.s3_read_only` | — | Concede `AmazonS3ReadOnlyAccess` ao EC2 |
| `aws_iam_instance_profile.ec2_profile` | `technova-ec2-instance-profile` | Vincula a IAM Role ao EC2 |
| `tls_private_key.technova` | — | Gera o par de chaves RSA 4096 localmente |
| `aws_key_pair.technova` | `technova-key` | Registra a chave pública na AWS |
| `local_sensitive_file.private_key` | `~/.ssh/technova-key.pem` | Salva a chave privada com permissão 0600 |
| `aws_instance.api` | `technova-ec2-api` | Instância t2.micro com a API Node.js rodando |

---

## Outputs Disponíveis

```bash
terraform output vpc_id              # ID da VPC
terraform output public_subnet_ids   # IDs das subnets públicas
terraform output private_subnet_ids  # IDs das subnets privadas
terraform output api_security_group_id
terraform output db_security_group_id
terraform output ec2_public_ip       # IP público da instância
terraform output api_url             # http://<IP>:3000
terraform output ssh_command         # Comando SSH completo
```

---

## Estrutura de Arquivos

```
aula-04/
├── main.tf              # Provider AWS, TLS e Local; versões e default_tags
├── variables.tf         # Declaração de todas as variáveis
├── terraform.tfvars     # Valores das variáveis (ajuste o owner_ra)
├── networking.tf        # VPC, Subnets, IGW e Route Tables
├── security_groups.tf   # SG da API e SG do banco
├── iam.tf               # IAM Role, Policy attachment e Instance Profile
├── ec2.tf               # AMI data source, Key Pair, User Data e instância EC2
├── outputs.tf           # Todos os outputs exportados
└── README.md            # Esta documentação
```
