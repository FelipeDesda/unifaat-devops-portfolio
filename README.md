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
