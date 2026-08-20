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
