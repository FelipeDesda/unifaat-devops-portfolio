# TechNova API

API Node.js/Express de gestão de pedidos, usada como base na aula de DevOps para praticar CI/CD, build de imagem Docker e publicação no Amazon ECR. O projeto expõe um endpoint de health check e um CRUD simples de pedidos, com testes em Jest/Supertest.

---

## Pré-requisitos

- **Node.js** `>= 18.0.0` (recomendado **20.x**, mesma versão base da imagem Docker `node:20-alpine`).
- **npm** (instalado junto com o Node).
- **Docker** (opcional, para construir/rodar a imagem e enviar ao ECR).
- **AWS CLI** configurado com as credenciais do **Learner Lab** (necessário apenas para o push ao ECR via `ecr-push.sh`).
- **Git** (necessário apenas para o push ao ECR — o script usa o SHA do commit atual).

---

## Como executar localmente

1. Instale as dependências (gera/consome o `package-lock.json`):

```bash
npm install
```

2. (Opcional) Defina a porta pela variável de ambiente `PORT`. O valor padrão é `3000`:

```bash
# Linux/macOS
export PORT=3000

# Windows (PowerShell)
$env:PORT = "3000"
```

3. Inicie o servidor com o script real do `package.json`:

```bash
npm start
```

A aplicação imprime `TechNova API rodando na porta 3000` e fica disponível em `http://localhost:3000`.

4. Confira o health check:

```bash
curl http://localhost:3000/health
```

> Nota: o servidor só inicia quando `NODE_ENV` é diferente de `test`. Os testes rodam sem subir a porta, importando o `app` via Supertest.

---

## Como executar os testes

Rodar a suíte Jest com cobertura:

```bash
npm test
```

Rodar em modo CI (mesma suíte, com flag `--ci`):

```bash
npm run test:ci
```

Outros scripts úteis:

```bash
npm run lint        # verifica o código com ESLint
npm run lint:fix    # corrige problemas de lint automaticamente
npm run build       # verificação de sintaxe (node --check server.js)
```

### O que a suíte cobre

`__tests__/server.test.js` (Jest + Supertest) valida:

- `GET /health` → status 200, `status: 'ok'` e `timestamp` presente.
- `GET /api/orders` → 200 e um array de pedidos com os campos `id`, `product`, `quantity` e `status`.
- `GET /api/orders/:id` → 200 para id existente e `404` para id inexistente.
- `POST /api/orders` → `201` criando um novo pedido com `status: 'pending'` e `400` quando faltam campos obrigatórios.

### Observação sobre o `__tests__/test-problems.js`

Este arquivo **não é um teste Jest** e **não deve ser executado**. Ele contém código problemático proposital (segredos hardcoded, SQL injection, `eval`, catch vazio, `console.log`) usado apenas para exerciciar a revisão automatizada por IA neste laboratório. Ele é ignorado pela suíte Jest porque não segue o padrão `*.test.js`.

---

## Como construir e rodar com Docker

A imagem é multi-stage (`node:20-alpine`), instala apenas dependências de produção com `npm ci --only=production`, roda como usuário não-root (`technova`) e define um `HEALTHCHECK` apontando para `/health`.

1. Construa a imagem:

```bash
docker build -t technova-api .
```

2. Rode o container mapeando a porta:

```bash
docker run -d -p 3000:3000 --name technova-api technova-api
```

3. Confira o health check do endpoint e do container:

```bash
# endpoint da API
curl http://localhost:3000/health

# status do HEALTHCHECK definido no Dockerfile
docker inspect --format='{{.State.Health.Status}}' technova-api
```

4. Encerre e remova o container quando terminar:

```bash
docker stop technova-api && docker rm technova-api
```

---

## Como enviar a imagem para o ECR

O script `ecr-push.sh` automatiza build, tag e push para o Amazon ECR.

### Pré-requisitos

- AWS CLI configurado com as credenciais do **Learner Lab** (variáveis de ambiente ou `aws configure`), na região `us-east-1`.
- Docker em execução.
- Estar em um repositório Git (o script gera a tag a partir do SHA do commit atual).
- Permissões no Learner Lab para `ecr:*` e `sts:GetCallerIdentity`.

### Uso

```bash
# conceda permissão de execução (Linux/macOS/WSL) na primeira vez
chmod +x ecr-push.sh

# execute
./ecr-push.sh
```

### O que o script faz

1. Resolve o ID da conta via `aws sts get-caller-identity` e monta o ECR URI `<account-id>.dkr.ecr.us-east-1.amazonaws.com/technova-api`.
2. Garante que o repositório ECR `technova-api` exista (`describe-repositories` ou `create-repository`).
3. Faz login no ECR com `aws ecr get-login-password`.
4. Constrói a imagem local: `docker build -t technova-api:local .`.
5. Gera **duas tags** e envia ambas:
   - `sha-<short-sha>` — rastreabilidade total ao commit do Git (ex.: `sha-a1b2c3d`).
   - `latest` — referência móvel apontando para o build mais recente.

Resultado:

```
<account-id>.dkr.ecr.us-east-1.amazonaws.com/technova-api:sha-<short-sha>
<account-id>.dkr.ecr.us-east-1.amazonaws.com/technova-api:latest
```

---

## Endpoints da API

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| `GET` | `/health` | Health check — retorna `status`, `timestamp` e `version` | 200 |
| `GET` | `/api/orders` | Lista todos os pedidos | 200 |
| `GET` | `/api/orders/:id` | Busca um pedido pelo id | 200 ou 404 |
| `POST` | `/api/orders` | Cria um pedido (valida `product` e `quantity`) | 201 ou 400 |

### Exemplos

```bash
# Health check
curl http://localhost:3000/health

# Listar pedidos
curl http://localhost:3000/api/orders

# Buscar pedido por id
curl http://localhost:3000/api/orders/1

# Criar pedido
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{"product": "Mouse Gamer", "quantity": 3}'
```

---

## Estrutura do projeto

```
technova-api/
├── server.js                # API Express (health check + CRUD de orders)
├── package.json             # Dependências e scripts (start, test, lint, build)
├── package-lock.json        # Lock para npm ci
├── Dockerfile               # Imagem multi-stage (node:20-alpine), usuário não-root
├── .dockerignore            # Exclusões do contexto de build
├── .eslintrc.json           # Configuração do ESLint
├── .gitignore               # node_modules, coverage, .env, etc.
├── ecr-push.sh              # Script de build/tag/push para o Amazon ECR
├── ia-cicd-analise.md       # Análise da esteira CI/CD e da revisão por IA
├── __tests__/
│   ├── server.test.js       # Suíte Jest (health + orders)
│   └── test-problems.js     # Código problemático proposital (NÃO é teste Jest)
└── README.md                # Este arquivo
```
