# Documentação e Evidências — IA no CI/CD da TechNova API

Este documento faz parte da entrega **Documentação e Evidências** do portfólio DevOps. Ele registra as decisões de registry, a estratégia de tagging, os padrões verificados pela revisão baseada em IA, o prompt/lógica de análise, a fronteira entre revisão automatizada e revisão humana, e as limitações do mecanismo.

> **Status de implementação:** o pipeline de CI (`.github/workflows/`) e o step de AI review não estão implementados como arquivos neste diretório `technova-api` — não existe a pasta `.github/workflows/` nem a pasta `.kiro/` neste projeto. O AI review é, portanto, o **mecanismo pretendido/proposto** para o pipeline de CI/CD, descrito aqui como design. Os demais elementos referenciados (`ecr-push.sh`, `Dockerfile`, `package.json`, suíte de testes) são arquivos reais e foram lidos para embasar este documento. Onde a leitura do projeto confirma um ponto, isso é indicado no texto.

---

## Por que o ECR foi escolhido como registry (vs ghcr.io / Docker Hub) e restrições do Learner Lab

O projeto publica a imagem da TechNova API no **Amazon ECR** (Elastic Container Registry) em vez do ghcr.io ou do Docker Hub. Essa escolha é determinada pelas restrições do **AWS Academy Learner Lab**, o ambiente onde a entrega é executada.

### Restrições do Learner Lab que motivam a escolha

- **Credenciais AWS temporárias por sessão.** O Learner Lab provisiona credenciais de curta duração (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) que expiram ao final de cada sessão. O ECR consome exatamente essas credenciais via IAM, sem necessidade de um segundo sistema de autenticação. O `ecr-push.sh` sequer precisa ler chaves explicitamente: ele obtém a conta com `aws sts get-caller-identity` e faz login com `aws ecr get-login-password`, reutilizando o perfil/credenciais AWS já presentes no ambiente.
- **Conta e VPC isoladas.** Cada laboratório roda em uma conta AWS isolada e efêmera, sem acesso a infraestrutura externa durável. Um registry externo (Docker Hub/ghcr.io) exigiria persistência fora da conta do lab, o que não se encaixa no modelo.
- **Sessões de tempo limitado.** As sessões do Learner Lab têm duração controlada. Um registry que dependa de tokens de longa duração (PAT do GitHub) ou de autenticação interativa adiciona fricção e pontos de falha dentro de uma janela curta. O ECR elimina essa fricção porque a autenticação é derivada das credenciais da própria sessão.
- **Integração com IAM e deploy em ECS/EKS.** O ECR é o registry nativo da AWS e se integra diretamente às políticas IAM do lab, às roles de execução de tarefas ECS e a eventuais deploys em EKS. Permissões de push/pull ficam resolvidas no modelo de confiança da AWS, sem um domínio de identidade adicional.

### Por que não ghcr.io

O ghcr.io exige um **Personal Access Token (PAT) do GitHub** com escopo `write:packages`, além de uma conta/repositório configurados. No Learner Lab isso significaria gerenciar um segundo conjunto de credenciais, armazená-las como secret e renová-las — exatamente o que as credenciais temporárias da AWS foram desenhadas para evitar. Além disso, o ghcr.io não tem integração nativa com as roles IAM usadas no deploy na AWS.

### Por que não Docker Hub

O Docker Hub impõe **rate limits** em pulls anônimos e autenticados (limite de pulls por janela por conta), o que atrapalha fluxos de CI que recriam imagens com frequência. Exige ainda uma conta e autenticação separadas das credenciais AWS do lab. Para um pipeline acadêmico que roda em sessões curtas e precisa empurrar a imagem para o ecossistema AWS, o Docker Hub adiciona um ponto de falha (limite de taxa + credencial extra) sem oferecer integração com o deploy.

### Síntese

O ECR é a escolha natural porque ele é o **registry nativo da AWS**, reutiliza as credenciais temporárias já presentes no Learner Lab, respeita o modelo de conta isolada e de sessão de tempo limitado, e se conecta diretamente ao deploy futuro em ECS/EKS via IAM — eliminando a autenticação paralela exigida pelo ghcr.io (PAT) e os rate limits do Docker Hub.

---

## Estratégia de tagging escolhida (e por quê)

A estratégia de tagging está implementada de fato no `ecr-push.sh`. O script aplica **duas tags** a cada publicação: uma **imutável baseada no SHA curto do commit** e uma **mutável `latest`**.

### O que o `ecr-push.sh` faz exatamente

```bash
# Tag pelo SHA curto do commit (rastreabilidade total)
SHA_TAG="sha-$(git rev-parse --short HEAD)"
```

O SHA é obtido do HEAD do repositório e transformado na tag `sha-<short-sha>` (por exemplo, `sha-a1b2c3d`). Depois, o script:

```bash
docker build -t "$REPO:local" .

docker tag "$REPO:local" "$ECR_URI:$SHA_TAG"
docker tag "$REPO:local" "$ECR_URI:latest"
docker push "$ECR_URI:$SHA_TAG"
docker push "$ECR_URI:latest"
```

Ou seja, a **mesma imagem** (`$REPO:local` produzida pelo build) recebe **duas referências no ECR**: `$ECR_URI:sha-<short-sha>` e `$ECR_URI:latest`. O `ECR_URI` é montado dinamicamente:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO"
```

E o repositório ECR é criado sob demanda se não existir:

```bash
aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --region "$REGION" >/dev/null
```

### Justificativa da dupla `sha-<short-sha>` + `latest`

- **Tag `sha-<short-sha>` (imutável, rastreável):** cada commit produz uma imagem única e identificável. Como o SHA do git é imutável, essa referência nunca muda de conteúdo, o que dá **rastreabilidade total** (sabe-se exatamente qual código está em qual imagem) e permite **rollback** determinístico (basta fazer o deploy apontar para uma tag `sha-...` anterior). É a referência usada para auditoria e para qualquer deploy de produção.
- **Tag `latest` (mutável, conveniência):** é um **ponteiro de conveniência** que sempre aponta para a imagem do build mais recente. Útil para comandos rápidos de `docker pull` durante o desenvolvimento e em ambientes não críticos do lab.

### Por que não usar apenas `:latest`

Usar somente `latest` é uma má prática para pipelines sérios porque:

- É **mutável**: a mesma tag passa a apontar para conteúdos diferentes ao longo do tempo.
- **Difícil de reverter**: não há como voltar a um estado anterior sem saber qual imagem ele era, já que a tag foi sobrescrita.
- **Sem rastreabilidade**: não há como associar a imagem rodando a um commit específico do repositório.
- Em ambientes com múltiplos deploys simultâneos, `latest` gera ambiguidade sobre qual versão está efetivamente em execução.

A estratégia adotada preserva o melhor dos dois mundos: a imutabilidade e rastreabilidade do SHA para operações confiáveis, e a conveniência do `latest` para uso rápido — desde que `latest` nunca seja a referência de um deploy controlado.

---

## Padrões que o AI review verifica

A revisão baseada em IA (mecanismo pretendido do pipeline) analisa o diff, o `Dockerfile` e os scripts de CI contra um checklist de padrões. Os padrões abaixo são derivados das boas práticas de Docker e Node.js e, onde aplicável, confrontados com o que existe no projeto.

### Segurança

- **Secrets hardcoded.** A IA sinaliza chaves, senhas e tokens literais no código. O próprio projeto inclui um arquivo deliberadamente problemático, `__tests__/test-problems.js`, com `const apiKey = 'sk-1234567890abcdef'` e `const dbPassword = 'super_secret_123'`, justamente para exercitar essa verificação.
- **`.env` dentro da imagem.** A IA confere se variáveis sensíveis não são copiadas para a imagem. O `.dockerignore` real do projeto já exclui `.env` e `.env.*` do contexto de build, o que é o comportamento esperado.
- **Execução como root.** A IA verifica se a imagem final define e usa um usuário não-root. O `Dockerfile` real cria o usuário `technova` (grupo `nodejs`, uid/gid 1001) e aplica `USER technova` antes do `CMD`.
- **`.dockerignore` ausente.** A IA checa a presença do arquivo. Ele existe no projeto e exclui `node_modules`, `.git`, `.env`, `coverage`, `__tests__`, `.github`, entre outros.

### Boas práticas de Docker

- **Multi-stage build.** A IA verifica a separação entre build e runtime para reduzir o tamanho da imagem final. O `Dockerfile` real tem dois estágios (`builder` e `runtime`), copiando apenas `node_modules` do builder.
- **Versão da imagem base pinned.** A IA confere se a imagem base tem versão fixa em vez de `latest`. O projeto usa `node:20-alpine`, ou seja, a *minor/major* está fixada em `20`, embora o pin seja por tag de versão e não por digest imutável — um ponto que a IA pode apontar como melhoria possível.
- **Minimizar camadas.** A IA verifica comandos encadeados (ex.: o `RUN addgroup ... && adduser ...` do projeto combina criação de grupo e usuário em uma camada).
- **Usuário não-root** (já coberto em segurança).

### Práticas Node.js

- **`npm ci` em vez de `npm install` em CI.** A IA verifica o uso de `npm ci` para builds reproduzíveis baseados no `package-lock.json`. O `Dockerfile` real usa `npm ci --only=production`, e o `package.json` oferece `test:ci` (`jest --coverage --forceExit --ci`) para o pipeline.
- **devDependencies fora da imagem de produção.** A IA confere se `devDependencies` não entram na imagem final. O `--only=production` no `npm ci` garante isso; além disso, o `.dockerignore` exclui `__tests__` e `*.test.js`.
- **Tratamento graceful de SIGTERM.** A IA verifica se a aplicação captura sinais de término para encerrar limpa. Hoje, `server.js` apenas faz `app.listen(...)` sem handler de `SIGTERM`/`SIGINT` — um achado possível da revisão.
- **Health checks.** A IA verifica a presença de um endpoint `/health` e a instrução `HEALTHCHECK` no `Dockerfile`. O projeto tem ambos: rota `/health` em `server.js` e `HEALTHCHECK ... wget ... http://localhost:3000/health` no `Dockerfile`.

### Cobertura de testes

- **Todos os testes devem passar antes do merge.** A IA confere que a suíte Jest está verde. A suíte real (`__tests__/server.test.js`) cobre `/health` (status, campo `status`, `timestamp`) e a API de orders (listagem, busca por id, 404, POST de criação e validação 400).
- A IA não confunde o arquivo `__tests__/test-problems.js` (que contém código deliberadamente ruim para testar a revisão) com um teste real a ser executado — ele não segue o padrão de testes Jest (`describe`/`it`) e não deve fazer parte da execução.

### Higiene de CI

- **Sem secrets em logs.** A IA verifica que o pipeline não imprime variáveis sensíveis.
- **Versões pinned de actions.** A IA confere que as actions do workflow usam tags/SHAs fixos em vez de `@main`/`@master` (mitigação de supply-chain). Como não há workflow implementado ainda, este item é uma recomendação de design.

---

## Prompt/lógica utilizada para a análise

A revisão é concebida como um step do pipeline que envia o diff, o `Dockerfile` e os scripts relevantes a um LLM com um prompt estruturado. A lógica é: aplicar um **checklist** classificando cada achado por **severidade** (blocker / médio / baixo), citar **arquivo e linha** específicos e emitir um **veredito estruturado** (aprova, aprova com ressalvas ou bloqueia o merge).

### Template de prompt de exemplo

O bloco abaixo é um modelo que um step de revisão via LLM no pipeline poderia usar:

```text
Você é um revisor de código especializado em CI/CD, Docker e Node.js para uma API
chamada TechNova API. Sua tarefa é analisar as mudanças propostas e emitir um
veredito estruturado.

ENTRADA:
- Diff do Pull Request (git diff)
- Dockerfile atual
- Scripts de CI/build (ex.: ecr-push.sh)
- package.json

CHECKLIST (verifique cada item e cite arquivo:linha quando encontrar problema):

Segurança:
- [ ] Secrets hardcoded (chaves, senhas, tokens literais)
- [ ] Arquivos .env no contexto da imagem
- [ ] Container executando como root
- [ ] Ausência de .dockerignore

Docker:
- [ ] Multi-stage build
- [ ] Imagem base com versão pinned (não usar :latest)
- [ ] Camadas minimizadas
- [ ] Usuário não-root definido e aplicado

Node.js:
- [ ] npm ci em vez de npm install no CI
- [ ] devDependencies fora da imagem de produção
- [ ] Tratamento graceful de SIGTERM/SIGINT
- [ ] Endpoint /health e instrução HEALTHCHECK

Testes:
- [ ] Todos os testes passam
- [ ] Cobertura não regrediu

Higiene de CI:
- [ ] Sem secrets impressos em logs
- [ ] Versões de actions pinned (tag ou SHA, não @main)

REGRAS DE SAÍDA:
1. Classifique cada achado como BLOCKER, MÉDIO ou BAIXO.
2. Para cada achado, informe: arquivo, linha, problema e correção sugerida.
3. Se houver qualquer BLOCKER, o veredito é "BLOQUEAR".
4. Se houver apenas MÉDIO/BAIXO, o veredito é "APROVAR COM RESSALVAS".
5. Se não houver achados, o veredito é "APROVAR".
6. Não invente problemas. Se não houver evidência no código, não aponte.

FORMATO DA RESPOSTA (JSON):
{
  "veredito": "APROVAR | APROVAR_COM_RESSALVAS | BLOQUEAR",
  "achados": [
    {
      "severidade": "BLOCKER | MEDIO | BAIXO",
      "arquivo": "caminho/do/arquivo",
      "linha": 12,
      "problema": "descrição objetiva",
      "correcao": "sugestão concreta"
    }
  ],
  "resumo": "parágrafo curto com o panorama geral"
}
```

### Lógica de decisão do veredito

- **BLOCKER** interrompe o pipeline: secrets em imagem, execução como root, falha de testes, dependências não pinned que afetem segurança.
- **MÉDIO/BAIXO** não interrompe, mas gera comentários no PR para correção posterior.
- A resposta em JSON permite que um step seguinte do pipeline consuma o `veredito` e decida automaticamente, sem depender de interpretação de texto livre.

---

## Quando confiar na IA vs quando exige review humano

A fronteira de decisão segue um princípio simples: a IA cuida do **determinístico e de pattern-matching**; humanos cuidam de **julgamento, contexto e mudanças de alto impacto**.

### Confiar na IA (revisão automatizada)

A IA é confiável para checagens rotineiras baseadas em padrões bem definidos, onde **falsos positivos são baratos de revisar**:

- Regras de lint e estilo de código (já parcialmente cobertas pelo ESLint do projeto, configurado em `.eslintrc.json` com `eslint:recommended`).
- Anti-padrões de segurança conhecidos por assinatura (secret hardcoded, `eval` com input, SQL injection por concatenação — exatamente os casos presentes em `__tests__/test-problems.js`).
- Boas práticas de Dockerfile (multi-stage, usuário não-root, `HEALTHCHECK`, `npm ci`).
- Execução e resultado dos testes (verde/vermelho da suíte Jest).
- Confirmação de presença de arquivos esperados (`.dockerignore`, `.gitignore`).

Esses itens têm natureza binária ou de padrão fixo, e um falso positivo é fácil e barato de confirmar olhando o código.

### Exigir review humano

A revisão humana é obrigatória quando há **julgamento, contexto ou impacto alto** envolvido:

- **Decisões arquiteturais.** Troca de framework, mudança de modelo de dados, nova dependência central.
- **Mudanças sensíveis à segurança.** Autenticação, criptografia, políticas IAM, alteração de permissões do ECR ou de roles de deploy. A IA pode sinalizar, mas a decisão de aceitar cabe a um humano.
- **Corretude de lógica de negócio.** A IA não conhece a intenção do negócio; regras de domínio (ex.: regras de status dos pedidos da TechNova) exigem quem entenda o domínio.
- **Mudanças em deployment/infrastructure-as-code.** Alterações em `ecr-push.sh`, no `Dockerfile` com impacto no runtime, ou em qualquer IaC, devem passar por humano.
- **Qualquer achado marcado como BLOCKER sobre o qual a IA está incerta.** Quando a IA sinaliza baixa confiança ou o achado depende de contexto de runtime, a decisão final é humana.

### Princípio

IA faz o trabalho repetitivo e determinístico (passa/falha, presença de padrão, verde dos testes). Humanos fazem o trabalho de julgamento (a mudança faz sentido? é segura para o contexto do Learner Lab? o impacto em produção é aceitável?). A combinação reduz carga cognitiva sem abrir mão de supervisão onde o risco é real.

---

## Limitações identificadas (falsos positivos, contexto limitado)

O mecanismo de AI review é útil, mas tem limitações que precisam ser declaradas com honestidade.

### Falsos positivos

A IA pode sinalizar código que está correto. Exemplos concretos:

- Uma string que **parece** um secret mas é um placeholder de exemplo ou um valor público (ex.: a `LABEL org.opencontainers.image.source="https://github.com/SEU-USUARIO/..."` no `Dockerfile` real poderia ser confundida com dado sensível).
- Um `console.log` que é legítimo em um contexto de startup (ex.: `console.log('TechNova API rodando na porta ${PORT}')` em `server.js`), mas que a IA marca como "log em produção".
- Um `catch` que parece "vazio" mas tem motivo válido (logs estruturados adiados, fallback intencional).

A mitigação é manter a barreira de severidade alta: só BLOCKER o que for inequivocamente problemático, e permitir que falsos positivos sejam descartados por um humano.

### Contexto limitado

A IA opera apenas sobre o texto do código e do diff. Ela não vê:

- **Comportamento em runtime.** Não executa a aplicação, então não observa vazamentos de memória, problemas de concorrência ou erros que só aparecem sob carga.
- **Ambiente de deploy completo.** Não conhece o estado real da conta AWS do Learner Lab, as roles IAM aplicadas, a VPC ou a configuração do ECS/EKS no momento do deploy.
- **Intenção de negócio.** Não sabe se uma regra aparentemente estranha é um requisito do domínio da TechNova.

### Fixes alucinados

Um LLM pode sugerir correções plausíveis mas **incorretas** — alterar código de uma forma que compila mas muda a semântica, ou propor um fix que introduz novo bug. Por isso, correções sugeridas pela IA devem ser tratadas como **sugestões** e não aplicadas automaticamente.

### Impossibilidade de verificar o deploy real na AWS

A IA pode confirmar que o `ecr-push.sh` está sintaticamente correto e segue boas práticas, mas **não consegue verificar o sucesso real do push/deploy** no ECR da conta do Learner Lab. Essa verificação depende de executar o pipeline de verdade, em uma sessão ativa do lab.

### Incapacidade de rodar a app contra serviços AWS reais

A IA não consegue executar a TechNova API contra serviços AWS reais do Learner Lab (ECR, IAM, eventual ECS). A suíte Jest (`__tests__/server.test.js`) valida a aplicação em nível de HTTP/Express, mas a IA não valida integrações com a AWS em runtime.

### Risco de checklist desatualizado

O checklist que orienta a IA reflete boas práticas de um momento. Conforme o ecossistema evolui (novas recomendações de Docker, mudanças no Node.js, novas ameaças de supply-chain), o checklist pode ficar **desatualizado**. Isso exige manutenção periódica do prompt/checklist, caso contrário a revisão perde eficácia e pode tanto deixar passar problemas novos quanto sinalizar problemas que já não são relevantes.

---

## Notas sobre embasamento (real vs. design pretendido)

- **Embasado em arquivos reais do projeto:** a estratégia de tagging (seção 2), a maior parte dos padrões de Docker e Node.js (seção 3, onde o `Dockerfile`, `.dockerignore`, `.eslintrc.json`, `package.json` e `server.js` foram lidos), e os exemplos de código problemático (`__tests__/test-problems.js`) e de suíte de testes (`__tests__/server.test.js`). A justificativa do ECR (seção 1) se apoia no uso real do ECR em `ecr-push.sh` e nas características conhecidas do AWS Academy Learner Lab.
- **Descrito como design pretendido:** o step de AI review em si (seção 4, o template de prompt), a higiene de CI com actions pinned (seção 3, pois não há workflow implementado) e a lógica de decisão automatizada do veredito. Não existe `.github/workflows/` nem `.kiro/` neste diretório `technova-api`, portanto o AI review é o **mecanismo proposto** para o pipeline, não um arquivo totalmente implementado.
