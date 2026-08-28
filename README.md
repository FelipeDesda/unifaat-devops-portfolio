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
