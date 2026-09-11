# Portfólio DevOps — UniFAAT 2026-2

**Aluno:** Felipe Damasceno 
**RA:** 6325128
**Disciplina:** DevOps — Centro Universitário UniFAAT  
**Professor:** Alexandre Tavares  
**Semestre:** 2026-2

## Sobre

Repositório de atividades e projetos da disciplina de DevOps.
Aqui documento minha evolução desde os fundamentos de Git e Docker até pipelines completas de CI/CD.

## Estrutura

- `aula-01/` — Fundamentos de Git e Docker
- `aula-02/` — Docker Compose e IA como Copiloto DevOps
- `aula-03/` — IAM com Terraform: Identidade e Acesso (Groups, Users, Policies, Service Role)
- `aula-04/` — Infraestrutura Multi-AZ na AWS com Terraform: VPC, Subnets, EC2, IAM Role e Security Groups
- `aula-05/` — RDS PostgreSQL + Remote State com S3 e Lock de State

## Aprendizados

# Aula 01 — Fundamentos de Git e Docker

## O que aprendi

- Aprendi a utilizar branches para desenvolver novas funcionalidades sem alterar diretamente a branch principal. Aprendi a realizar commits com mensagens descritivas, seguindo o padrão Conventional Commits. Aprendi a fazer merge de uma branch de funcionalidade para a branch main. Aprendi a importância do Git para controlar versões e acompanhar o histórico das alterações. Aprendi a utilizar comandos como git init, git add, git commit, git checkout e git merge.
- Aprendi que containers permitem executar uma aplicação em um ambiente isolado e padronizado. Aprendi a criar um Dockerfile para definir como a aplicação deve ser construída e executada. Aprendi a utilizar imagens Docker e criar containers a partir delas. Aprendi a expor portas para permitir o acesso à aplicação que está rodando dentro do container. Aprendi a utilizar o .dockerignore para evitar que arquivos desnecessários sejam copiados para a imagem.

## Comandos Git praticados

- git init — inicializar o repositório. git checkout -b feature/aula-01-app — criar e acessar uma branch de funcionalidade. git add — adicionar arquivos para o commit. git commit — registrar as alterações no histórico. git checkout main — voltar para a branch principal. git merge feature/aula-01-app — mesclar a branch de funcionalidade com a main. git remote add origin — conectar o repositório local ao GitHub. git push — enviar as alterações para o GitHub.

## Comandos Docker praticados

- docker build — criar uma imagem a partir do Dockerfile. docker run — criar e executar um container. docker ps — verificar os containers em execução. docker logs — visualizar os logs do container. docker stop — parar um container em execução. docker rm — remover um container. curl — testar as respostas da API nos endpoints / e /health.

## Como executar este container

```bash
cd aula-01/app
docker build -t portfolio-aula01:1.0 .
docker run -d -p 3000:3000 portfolio-aula01:1.0
curl http://localhost:3000
```

---

# Aula 02 — Docker Compose e IA como Copiloto DevOps

## O que aprendi

- Aprendi a orquestrar múltiplos containers com Docker Compose, definindo uma stack completa (API, banco de dados e cache) em um único arquivo `docker-compose.yml`.
- Aprendi a usar variáveis de ambiente com interpolação do arquivo `.env`, mantendo credenciais e configurações sensíveis fora do código versionado.
- Aprendi a configurar healthchecks nos serviços para verificar se o container está realmente pronto para receber conexões, usando comandos como `pg_isready` (PostgreSQL) e `redis-cli ping` (Redis).
- Aprendi a usar `depends_on` com `condition: service_healthy`, garantindo que a API só inicie após o banco de dados e o cache passarem nos healthchecks.
- Aprendi a criar redes bridge customizadas no Docker Compose, permitindo que os serviços se comuniquem pelo nome do hostname (ex: `postgres`, `redis`) sem expor as portas ao host.
- Aprendi a usar volumes nomeados para persistência de dados do PostgreSQL, garantindo que os dados sobrevivam à recriação dos containers.
- Aprendi a configurar a política `restart: unless-stopped`, tornando os serviços resilientes a falhas e reinicializações do Docker.
- Aprendi a utilizar imagens Alpine (`postgres:15-alpine`, `redis:7-alpine`, `node:20-alpine`) para reduzir o tamanho final das imagens.
- Aprendi a usar a IA como copiloto DevOps: gerar um output inicial com um prompt bem estruturado e depois validar criticamente o resultado, identificando o que foi acertado e o que precisou ser corrigido ou complementado.

## Comandos Docker Compose praticados

- `docker compose up -d` — subir todos os serviços da stack em modo detached.
- `docker compose down` — parar e remover os containers da stack.
- `docker compose down -v` — parar, remover containers e também os volumes nomeados.
- `docker compose ps` — listar o status dos serviços em execução.
- `docker compose logs -f <serviço>` — acompanhar os logs de um serviço em tempo real.
- `docker compose build` — construir (ou reconstruir) a imagem de um serviço a partir do Dockerfile.
- `docker inspect <container>` — inspecionar detalhes de configuração de um container.

## Conceitos-chave

- **Multi-service stack:** uma aplicação real raramente roda em um único container; o Compose permite descrever toda a infraestrutura como código.
- **Healthcheck:** verificação ativa de saúde que permite ao Compose e ao Docker saber se um serviço está realmente funcional, não apenas em execução.
- **Rede bridge customizada:** isola a comunicação entre serviços e habilita resolução de nomes por hostname, sem expor portas desnecessariamente ao host.
- **Volume nomeado:** armazenamento gerenciado pelo Docker que persiste dados entre reinicializações, essencial para bancos de dados.
- **IA como copiloto:** a IA acelera a geração de scaffolding e boilerplate, mas o profissional DevOps precisa revisar o output — verificando variáveis, credenciais, healthchecks e alinhamento com boas práticas — antes de usar em produção.

## Como executar esta stack

```bash
cd aula-02
# Copie o arquivo de exemplo e ajuste as variáveis
cp .env.example .env

# Suba todos os serviços
docker compose up -d

# Verifique o status e aguarde os healthchecks passarem
docker compose ps

# Teste a API
curl http://localhost:3000
curl http://localhost:3000/health

# Para encerrar
docker compose down
```


---

# Aula 03 — Terraform + IAM | Felipe Damasceno (6325128)

## Design da Estrutura IAM

A estrutura foi pensada para refletir as responsabilidades reais de uma equipe de engenharia, onde diferentes perfis precisam de acessos distintos sem que um interfira no trabalho do outro.

Criei dois groups porque existem dois perfis claramente diferentes na TechNova:

- **`SEURA-technova-developers`** agrupa os desenvolvedores, que precisam consultar artefatos no S3 (leitura de builds, configs, assets) mas não têm nenhuma razão de negócio para modificar ou deletar nada na infraestrutura.
- **`SEURA-technova-platform-eng`** agrupa os engenheiros de plataforma, que precisam operar instâncias EC2 (ligar, desligar, monitorar) e também gravar/ler dados no S3 — trabalho operacional mais amplo.

A separação em groups (em vez de policies por usuário) segue o mesmo princípio de times reais: quando um novo dev entra, basta adicioná-lo ao grupo certo e ele herda as permissões corretas automaticamente. Não há risco de esquecer de anexar ou revogar uma policy individualmente.

O `rafael-platform` pertence aos dois grupos porque ele acumula funções: é dev e também cuida da plataforma. Isso demonstra que um usuário pode herdar permissões de múltiplos groups — a AWS une os Allows de todos eles, e qualquer Deny de qualquer source prevalece sobre tudo.

O `lucas-intern` fica apenas no grupo `developers`, mas ainda assim tem uma policy inline restritiva diretamente no seu usuário. Isso cria uma segunda camada de proteção: mesmo que o grupo `developers` ganhe novas permissões no futuro, o estagiário continua limitado ao mínimo (`ListBucket` + `GetObject`), pois o Deny inline na sua conta sobrepõe qualquer Allow herdado.

Cada policy foi desenhada com escopo mínimo:

- **`SEURA-technova-s3-read`** — permite apenas listar e baixar objetos de buckets cujo nome começa com `technova-`. Nenhuma ação de escrita, nenhum acesso a outros buckets da conta.
- **`SEURA-technova-ec2-s3-full`** — os Describes de EC2 são sem restrição de resource porque a API da AWS exige `*` para ações de listagem. Já o Start/Stop usa uma `Condition` de tag (`Project = TechNova`), então engenheiros só conseguem ligar/desligar instâncias que pertencem ao projeto, não qualquer instância da conta.
- **`SEURA-technova-deny-destructive`** — Deny explícito sobre Delete\* e Terminate\* em S3, EC2 e IAM. Serve como guardrail: independente de qualquer Allow que um dev venha a receber, ele nunca conseguirá apagar um objeto, encerrar uma instância ou deletar um usuário.

---

## Princípio do Menor Privilégio

O princípio do menor privilégio diz que uma identidade (usuário, grupo, serviço) deve ter acesso apenas ao que é estritamente necessário para realizar sua função — nada mais. O objetivo é reduzir a superfície de ataque: se uma credencial for comprometida, o invasor só consegue fazer o que aquela identidade poderia fazer, não tudo na conta.

**Exemplo 1 — Escopo de resource em vez de `*`:**  
Na policy `s3-read`, o resource é `arn:aws:s3:::technova-*` e não `arn:aws:s3:::*`. Isso significa que mesmo que existam centenas de outros buckets na conta AWS (logs, backups, dados de outros projetos), um desenvolvedor da TechNova simplesmente não enxerga nenhum deles. Não é um Deny ativo — é a ausência de Allow, que já é suficiente.

**Exemplo 2 — Condition de tag no EC2:**  
Na policy `ec2-s3-full`, o Start/Stop de instâncias tem a condition `ec2:ResourceTag/Project = TechNova`. Um engenheiro de plataforma não consegue acidentalmente (ou maliciosamente) desligar uma instância de outro projeto ou de outro time que esteja na mesma conta AWS. Sem essa condition, bastaria ter a policy para operar qualquer instância da organização.

**O que aconteceria com `AmazonS3FullAccess`:**  
Essa policy managed da AWS concede `s3:*` em `Resource: *`, o que significa que qualquer desenvolvedor poderia listar, ler, escrever e **deletar** objetos em qualquer bucket da conta — incluindo backups, logs de auditoria, dados de outros projetos e até o próprio bucket do Terraform state. Um erro de script ou uma credencial vazada poderia destruir dados irrecuperáveis de toda a organização. Com a custom policy, o pior caso de uma credencial comprometida é um atacante conseguindo baixar arquivos de buckets `technova-*` — um raio de impacto muito menor e controlado.

---

## Diagrama de Permissões

```
╔══════════════════════════════════════════════════════════════════════╗
║                     TECHNOVA — IAM Overview                         ║
╚══════════════════════════════════════════════════════════════════════╝

  USERS                    GROUPS                    POLICIES
  ──────                   ──────                    ────────
                           ┌─────────────────────┐
  juliana-dev ────────────►│                     ├──► s3-read
                           │  technova-          │    (s3:GetObject
  lucas-intern ───────────►│  developers         │     s3:ListBucket
     │                     │                     │     em technova-*)
     │ [inline policy]     └─────────────────────┘
     └──► lucas-restricted      │
          (somente              └──► deny-destructive
           ListBucket+               (Deny Delete*
           GetObject;                 Terminate*
           Deny escrita)              em S3/EC2/IAM)

  rafael-platform ─────────────────────────────────► (herda developers acima)
        │
        │          ┌─────────────────────┐
        └─────────►│  technova-          ├──► ec2-s3-full
                   │  platform-eng       │    (EC2 Describe*
                   │                     │     EC2 Start/Stop
                   └─────────────────────┘      [tag: Project=TechNova]
                                                 S3 read/write
                                                 em technova-*)


  SERVICE ROLE (EC2 → S3)
  ───────────────────────
  ┌──────────────────┐   Trust Policy        ┌────────────────────────┐
  │  EC2 Instance    │──(ec2.amazonaws.com)──►│  technova-ec2-role     │
  │                  │   sts:AssumeRole       │                        │
  │  [usa o profile] │                        │  Permissions:          │
  └──────────────────┘                        │  s3:GetObject          │
         │                                    │  s3:PutObject          │
         │  Instance Profile                  │  s3:DeleteObject       │
         └──► technova-ec2-profile            │  em technova-app-data-*│
              (wrapper obrigatório)           └────────────────────────┘
```

> A instância EC2 nunca precisa de credenciais estáticas (access key / secret key). O Instance Profile injeta credenciais temporárias automaticamente via metadata service (`169.254.169.254`), renovadas a cada hora pela AWS. Esse é o padrão seguro para workloads em cloud.


---

# Aula 04 — Infraestrutura Multi-AZ na AWS com Terraform | Felipe Damasceno (6325128)

## O que aprendi

- Aprendi a criar uma VPC completa com Terraform, definindo blocos CIDR, subnets públicas e privadas distribuídas em múltiplas Availability Zones (`us-east-1a` e `us-east-1b`).
- Aprendi o conceito de Multi-AZ: distribuir recursos em duas AZs garante alta disponibilidade — se uma AZ falhar, os recursos da outra continuam operando.
- Aprendi a diferença entre subnets públicas e privadas: subnets públicas possuem rota para o Internet Gateway e hospedam recursos acessíveis pela internet (como a EC2 com a API); subnets privadas ficam isoladas, prontas para hospedar bancos de dados no futuro.
- Aprendi a criar e associar um Internet Gateway (IGW) e uma Route Table pública que direciona todo o tráfego (`0.0.0.0/0`) para o IGW.
- Aprendi a criar Security Groups com regras de ingresso e egresso precisas: portas 22 (SSH) e 3000 (API) abertas ao mundo, e porta 5432 (PostgreSQL) restrita ao CIDR da VPC.
- Aprendi a criar uma IAM Role para instância EC2 com Trust Policy para `ec2.amazonaws.com`, Instance Profile como wrapper obrigatório, e policy `AmazonS3ReadOnlyAccess` anexada — sem precisar de credenciais estáticas na instância.
- Aprendi a gerar um Key Pair RSA 4096 diretamente pelo Terraform (provider `tls`), registrar a chave pública na AWS e salvar a privada localmente com permissão `0600`.
- Aprendi a usar o recurso `aws_ami` com `data source` e filtros para selecionar a AMI mais recente do Amazon Linux 2023 automaticamente.
- Aprendi a escrever um User Data em `bash` para configurar automaticamente a instância: instalar Node.js via `dnf`, criar uma API simples com endpoints `/` e `/health`, e registrar a aplicação como serviço `systemd` com `Restart=on-failure`.
- Aprendi a usar `default_tags` no bloco `provider` para aplicar tags (`Project`, `Environment`, `ManagedBy`, `Owner`) a todos os recursos de forma centralizada.
- Aprendi a exportar outputs úteis (`ec2_public_ip`, `api_url`, `ssh_command`, IDs de VPC e subnets) para facilitar os testes e evidências do lab.

## Conceitos-chave

- **Multi-AZ:** redundância geográfica dentro de uma região AWS; base de qualquer arquitetura de produção de alta disponibilidade.
- **Subnet pública vs. privada:** isolamento por design — apenas o que precisa de acesso externo fica exposto; bancos de dados e serviços internos ficam na camada privada sem rota para a internet.
- **Internet Gateway + Route Table:** o IGW é a porta de entrada/saída da VPC para a internet; a Route Table define quais subnets têm essa rota e quais não têm.
- **Security Group:** firewall stateful no nível da instância; regras de ingresso controlam o que entra, regras de egresso controlam o que sai.
- **IAM Instance Profile:** mecanismo que injeta credenciais temporárias na EC2 via metadata service (`169.254.169.254`), eliminando a necessidade de access keys estáticas no servidor.
- **User Data + systemd:** inicialização automática da aplicação no boot da instância com resiliência a falhas; mais robusto que executar o processo em background manualmente.
- **Key Pair gerenciado pelo Terraform:** chave RSA criada, registrada na AWS e salva localmente em uma única execução de `terraform apply`, sem passo manual.

## Arquitetura Provisionada

```
Internet → IGW → Route Table Pública → Subnet Pública (us-east-1a) → EC2 (porta 22 / 3000)

VPC: technova-vpc (10.0.0.0/16)
├── Subnet Pública 1  — 10.0.1.0/24 (us-east-1a) → EC2 API Node.js
├── Subnet Pública 2  — 10.0.3.0/24 (us-east-1b) → (Load Balancer futuro)
├── Subnet Privada 1  — 10.0.2.0/24 (us-east-1a) → (RDS futuro)
└── Subnet Privada 2  — 10.0.4.0/24 (us-east-1b) → (RDS futuro)
```

## Recursos Criados

| Recurso Terraform | Nome AWS | Função |
|---|---|---|
| `aws_vpc.main` | `technova-vpc` | Rede isolada para toda a infraestrutura |
| `aws_subnet.public[0/1]` | `technova-subnet-public-1/2` | Subnets públicas Multi-AZ |
| `aws_subnet.private[0/1]` | `technova-subnet-private-1/2` | Subnets privadas Multi-AZ (banco futuro) |
| `aws_internet_gateway.main` | `technova-igw` | Porta de saída para a internet |
| `aws_route_table.public` | `technova-rt-public` | Rota `0.0.0.0/0` → IGW |
| `aws_security_group.api` | `technova-sg-api` | Permite SSH (22) e API (3000) |
| `aws_security_group.db` | `technova-sg-db` | Permite PostgreSQL (5432) apenas da VPC |
| `aws_iam_role.ec2_role` | `technova-ec2-role` | IAM Role com `S3ReadOnlyAccess` para o EC2 |
| `aws_iam_instance_profile.ec2_profile` | `technova-ec2-instance-profile` | Vincula a Role ao EC2 |
| `tls_private_key.technova` + `aws_key_pair.technova` | `technova-key` | Par de chaves RSA 4096 gerado pelo Terraform |
| `aws_instance.api` | `technova-ec2-api` | Instância `t2.micro` com API Node.js via systemd |

## Como Executar

```bash
cd aula-04

# 1. Ajuste o RA no arquivo de variáveis
#    Edite terraform.tfvars e defina: owner_ra = "SEU-RA"

# 2. Inicializar
terraform init

# 3. Revisar o plano
terraform plan

# 4. Aplicar (aguarde ~3 min para o User Data concluir)
terraform apply

# 5. Testar a API
curl http://$(terraform output -raw ec2_public_ip):3000
curl http://$(terraform output -raw ec2_public_ip):3000/health

# 6. Destruir ao final do lab
terraform destroy
```

---

# Aula 05 — RDS PostgreSQL e Remote State | Felipe Damasceno (6325128)

Infraestrutura completa provisionada com Terraform, incluindo VPC, EC2, RDS PostgreSQL e remote state protegido no S3 com locking no DynamoDB.

## Estrutura específica

```text
aula-05/
├── bootstrap/             # Backend remoto: S3 + DynamoDB, com state local
├── backend.tf             # Configuração do remote state no S3
├── providers.tf           # Provider AWS, versões e default_tags
├── variables.tf           # Variáveis da infraestrutura principal
├── terraform.tfvars.example
├── vpc.tf                 # VPC, subnets, gateways e route tables
├── security_groups.tf     # Security Groups da EC2 e do RDS
├── rds.tf                 # DB Subnet Group e RDS PostgreSQL
├── ec2.tf                 # EC2 com user_data e cliente psql
└── outputs.tf             # IDs, endpoints, IPs e comandos úteis
```

## Pré-requisitos

- Terraform >= 1.5.0
- AWS CLI configurado (`aws configure`)
- Key Pair criado na AWS para acesso SSH à EC2
- Permissões IAM para EC2, RDS, VPC, S3 e DynamoDB

## O que aprendi

- Aprendi a provisionar um banco de dados gerenciado com `aws_db_instance`, configurando PostgreSQL 15, classe de instância, storage encriptado e isolamento de rede — sem nenhuma credencial de acesso exposta no código.
- Aprendi a criar um `aws_db_subnet_group` com subnets privadas em duas AZs distintas, requisito obrigatório da AWS para o RDS mesmo em modo `multi_az = false`.
- Aprendi a diferenciar `publicly_accessible = false` (RDS sem IP público, acessível apenas por recursos dentro da VPC) de uma subnet pública: o isolamento real vem da combinação entre ausência de IP público e regras de Security Group.
- Aprendi a configurar o Remote State do Terraform usando um bucket S3 com versionamento, encriptação SSE-S3 e bloqueio de acesso público — garantindo que o `terraform.tfstate` não fique apenas na máquina local.
- Aprendi a usar uma tabela DynamoDB com chave `LockID` para impedir que dois operadores executem `terraform apply` simultaneamente e corrompam o state.
- Aprendi que o backend precisa existir **antes** do `terraform init`; por isso, o módulo `bootstrap/` usa state local para preparar o S3 e o DynamoDB.
- Aprendi a criar uma Route Table privada sem rota para internet e associá-la às subnets do RDS, garantindo isolamento completo do banco mesmo dentro da mesma VPC.
- Aprendi a usar `source_security_group_id` no Security Group do RDS em vez de um CIDR aberto, restringindo o acesso à porta 5432 exclusivamente às instâncias EC2 que possuem o SG da API — princípio do menor privilégio aplicado em nível de rede.
- Aprendi a instalar o cliente `postgresql15` no EC2 via User Data para validar a conectividade ao RDS sem sair da infraestrutura provisionada.
- Aprendi a marcar outputs como `sensitive = true` no Terraform para que strings de conexão e comandos com senha não apareçam no log do `terraform apply`.

## Conceitos-chave

- **Remote State:** armazenar o `terraform.tfstate` em um backend remoto compartilhado (S3) é essencial para times — qualquer membro da equipe trabalha sempre com o estado mais recente e não há risco de conflito de state local.
- **State Lock:** a tabela DynamoDB impede que dois `terraform apply` rodem ao mesmo tempo, evitando corrupção do state.
- **RDS vs. banco em EC2:** o RDS é um serviço gerenciado — a AWS cuida de backups, patches de segurança, failover e réplicas. Rodar PostgreSQL em EC2 manualmente exige toda essa operação manual, aumentando risco operacional.
- **DB Subnet Group:** agrupamento de subnets que define em quais AZs o RDS pode ser colocado; exige ao menos 2 AZs para garantir capacidade de failover mesmo em modo single-AZ.
- **`publicly_accessible = false`:** o RDS não recebe IP público. O único caminho para acessá-lo é por dentro da VPC — geralmente via EC2 (bastion) ou uma conexão SSH com port forwarding.
- **Encriptação em repouso (`storage_encrypted = true`):** dados armazenados no volume do RDS são encriptados com AES-256 gerenciado pela AWS (KMS). Boa prática mínima para qualquer ambiente.
- **Security Group source por SG:** ao referenciar outro Security Group como source (em vez de um bloco CIDR), a regra se aplica automaticamente a qualquer nova instância EC2 que receba aquele SG — sem precisar atualizar a regra manualmente quando IPs mudam.

## Arquitetura Provisionada

```
Internet → IGW → Route Table Pública → Subnet Pública (us-east-1a) → EC2 (porta 22 / 3000)
                                                      │
                                                      │ PostgreSQL :5432 (apenas via SG)
                                                      ▼
                              Subnet Privada 1  10.0.10.0/24 (us-east-1a) ─┐
                              Subnet Privada 2  10.0.11.0/24 (us-east-1b) ─┴─► RDS PostgreSQL 15

Remote State:
  S3 Bucket   → technova-tfstate-unifaat   (versionado + encriptado + acesso público bloqueado)
  DynamoDB    → technova-tfstate-lock      (LockID — controle de concorrência)

VPC: technova-vpc (10.0.0.0/16)
├── Subnet Pública   — 10.0.1.0/24   (us-east-1a) → EC2 API
├── Subnet Privada 1 — 10.0.10.0/24  (us-east-1a) → RDS (DB Subnet Group)
└── Subnet Privada 2 — 10.0.11.0/24  (us-east-1b) → RDS (DB Subnet Group)
```

## Recursos Criados

| Recurso Terraform | Nome AWS | Função |
|---|---|---|
| `aws_vpc.main` | `technova-vpc` | Rede isolada para toda a infraestrutura |
| `aws_subnet.public` | `technova-subnet-public-us-east-1a` | Subnet pública para o EC2 |
| `aws_subnet.private_1` | `technova-subnet-private-us-east-1a` | Subnet privada AZ-1 para o RDS |
| `aws_subnet.private_2` | `technova-subnet-private-us-east-1b` | Subnet privada AZ-2 para o RDS |
| `aws_internet_gateway.main` | `technova-igw` | Porta de saída para a internet |
| `aws_route_table.public` | `technova-rt-public` | Rota `0.0.0.0/0` → IGW |
| `aws_route_table.private` | `technova-rt-private` | Sem rota para internet (isolamento RDS) |
| `aws_security_group.api` | SG do EC2 | Permite SSH (22) e API (3000) |
| `aws_security_group.rds` | SG do RDS | Permite PostgreSQL (5432) apenas do SG do EC2 |
| `aws_db_subnet_group.main` | `technova-db-subnet-group` | Agrupa as subnets privadas para o RDS |
| `aws_db_instance.postgres` | `technova-postgres` | RDS PostgreSQL 15 (`db.t3.micro`, 20 GB, encriptado) |
| `aws_instance.api` | EC2 da API | Instância com `psql` para testar conectividade ao RDS |
| `aws_s3_bucket_versioning.tfstate` | S3 `technova-tfstate-unifaat` | Versionamento do Terraform state |
| `aws_s3_bucket_server_side_encryption_configuration.tfstate` | S3 | Encriptação SSE-AES256 |
| `aws_s3_bucket_public_access_block.tfstate` | S3 | Bloqueio completo de acesso público |
| `aws_dynamodb_table.tfstate_lock` | `technova-tfstate-lock` | Lock do Terraform state |

## Como Executar

```bash
cd aula-05

# 1. Preparar o remote state (executar uma vez)
cd bootstrap
terraform init
terraform plan
terraform apply
cd ..

# 2. Configurar variáveis
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars: key_pair_name, db_username, db_password

# 3. Inicializar (conecta ao backend S3)
terraform init

# 4. Revisar o plano
terraform plan

# 5. Aplicar (~10–15 min por causa do RDS)
terraform apply

# 6. Verificar state no S3
aws s3 ls s3://technova-tfstate-unifaat/aula-05/

# 7. Testar conexão ao RDS via EC2
ssh -i minha-chave.pem ec2-user@$(terraform output -raw ec2_public_ip)
psql -h $(terraform output -raw rds_endpoint) -U technova_admin -d technova_db -W

# 8. Destruir ao final do lab
terraform destroy
```

## Remote State e outputs

O bucket `technova-tfstate-unifaat` armazena o state em `aula-05/terraform.tfstate`. O bootstrap aplica versionamento, SSE-AES256, bloqueio de acesso público e nega requisições sem HTTPS ou sem encriptação. A tabela `technova-tfstate-lock` usa a chave `LockID` para controlar concorrência.

Outputs principais:

- `vpc_id`, `public_subnet_id` e `private_subnet_ids`
- `ec2_public_ip`, `ec2_public_dns` e `ec2_ssh_command`
- `rds_endpoint`, `rds_port` e `rds_db_name`
- `rds_connection_string` e `psql_command` como outputs sensíveis
- `tfstate_bucket`

## Validações

- `terraform init` exibe `Successfully configured the backend "s3"`.
- `aws s3 ls s3://technova-tfstate-unifaat/aula-05/` lista o state remoto.
- O RDS está em subnets privadas, com `publicly_accessible = false` e `storage_encrypted = true`.
- O Security Group do RDS permite a porta 5432 somente a partir do Security Group da EC2.
- `terraform.tfvars` e arquivos `.pem` permanecem fora do repositório.

## Decisões de projeto

| Decisão | Justificativa |
|---|---|
| `multi_az = false` | Reduz custo em ambiente de laboratório. |
| `skip_final_snapshot = true` | Não cria snapshot final durante a destruição do lab. |
| `publicly_accessible = false` | Mantém o RDS acessível apenas pela VPC. |
| `storage_encrypted = true` | Protege os dados armazenados. |
| `backup_retention_period = 0` | Mantém o laboratório dentro do objetivo de baixo custo. |
| SG do RDS referenciando o SG da EC2 | Restringe a conexão PostgreSQL ao servidor de aplicação. |
