# Análise do Uso de IA — Aula 02 TF

## Prompt Utilizado

Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. A API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis de ambiente com interpolação de arquivo .env. Adicione healthchecks, depends_on com condition, e restart policy unless-stopped.

## Output Original do Kiro

# =============================================================
# docker-compose.yml — TechNova API (Aula 02)
# Stack: Node.js 20 (build local) + PostgreSQL 15 + Redis 7
# Todas as variáveis sensíveis são lidas do arquivo .env
# =============================================================

services:

  # -----------------------------------------------------------
  # api — Aplicação Node.js construída a partir do Dockerfile
  #        local. Só sobe após postgres e redis estarem healthy.
  # -----------------------------------------------------------
  api:
    build:
      context: .           # usa o Dockerfile na raiz do projeto
      dockerfile: Dockerfile
    container_name: technova_api
    ports:
      - "${APP_PORT}:3000" # porta do host mapeada via .env
    environment:
      NODE_ENV: ${NODE_ENV}
      PORT: ${APP_PORT}
      # Variáveis de conexão com o banco (nomes que app.js espera)
      DB_HOST: ${DB_HOST}
      DB_PORT: ${DB_PORT}
      DB_NAME: ${DB_NAME}
      # Variáveis de conexão com o cache (nomes que app.js espera)
      REDIS_HOST: ${REDIS_HOST}
      REDIS_PORT: ${REDIS_PORT}
    depends_on:
      # A API só inicia quando postgres e redis já passaram no healthcheck
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - technova_network
    restart: unless-stopped  # reinicia automaticamente, exceto parada manual

  # -----------------------------------------------------------
  # postgres — Banco de dados relacional com volume nomeado
  #             para garantir persistência dos dados entre
  #             reinicializações do container.
  # -----------------------------------------------------------
  postgres:
    image: postgres:15-alpine
    container_name: technova_postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}           # nome do banco inicial
      POSTGRES_USER: ${POSTGRES_USER}       # usuário proprietário
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD} # senha — vem do .env
    volumes:
      - postgres_data:/var/lib/postgresql/data  # volume nomeado para persistência
    networks:
      - technova_network
    restart: unless-stopped
    healthcheck:
      # pg_isready verifica se o servidor aceita conexões
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s      # verifica a cada 10 segundos
      timeout: 5s        # tempo máximo para o comando responder
      retries: 5         # tentativas antes de marcar como unhealthy
      start_period: 10s  # janela de graça enquanto o postgres inicializa

  # -----------------------------------------------------------
  # redis — Cache em memória. Sem volume pois dados de cache
  #          são efêmeros por natureza.
  # -----------------------------------------------------------
  redis:
    image: redis:7-alpine
    container_name: technova_redis
    networks:
      - technova_network
    restart: unless-stopped
    healthcheck:
      # redis-cli ping retorna PONG quando o servidor está pronto
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s

# =============================================================
# Volumes nomeados — gerenciados pelo Docker, sobrevivem a
# "docker compose down" (use -v para remover junto).
# =============================================================
volumes:
  postgres_data:
    driver: local

# =============================================================
# Rede bridge customizada — isola os serviços e permite
# resolução de nomes por hostname (postgres, redis, api).
# =============================================================
networks:
  technova_network:
    driver: bridge


## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|------------|---------|
| [Ex: Adicionei healthcheck no Redis] | [O Kiro não incluiu, é boa prática] |
| [Ex: Mudei senhas para usar .env] | [Estavam hardcoded no output do Kiro] |
| [Ex: Corrigi imagem do Redis] | [Kiro usou versão que não existe] |
| ... | ... |

## O que o Kiro Acertou

- Boa organização do docker-compose.yml, separando claramente os serviços api, postgres e redis.
- Uso de variáveis de ambiente (.env), evitando deixar diretamente no arquivo valores como senha do PostgreSQL e portas.
- Uso de volumes nomeados no PostgreSQL, garantindo a persistência dos dados mesmo após a recriação do container.
- Configuração de healthcheck tanto para PostgreSQL quanto para Redis, permitindo verificar se os serviços estão realmente prontos.
- Uso de depends_on com condition: service_healthy, fazendo a API aguardar PostgreSQL e Redis ficarem saudáveis antes de iniciar.
- Uso de imagens Alpine, como postgres:15-alpine e redis:7-alpine, que são alternativas mais leves para os containers.
- Configuração de restart: unless-stopped, permitindo que os serviços sejam reiniciados automaticamente após falhas ou reinicializações do Docker.
- Criação de uma rede Docker personalizada, facilitando a comunicação entre os serviços e a resolução de nomes como postgres e redis.
- Mapeamento da porta da API através do .env, permitindo alterar a porta do host sem modificar o docker-compose.yml.
- Comentários explicativos no arquivo, facilitando a compreensão da finalidade de cada configuração, especialmente para fins didáticos.
- Separação adequada dos serviços, seguindo uma arquitetura comum de aplicações: API + banco de dados + cache.
- Configuração relativamente simples e adequada para um ambiente de desenvolvimento, sem adicionar complexidade desnecessária.

## O que o Kiro Errou ou Omitiu

- As credenciais do PostgreSQL não são passadas para a API. O postgres recebe POSTGRES_USER e POSTGRES_PASSWORD, mas a API só recebe DB_HOST, DB_PORT e DB_NAME. Se a aplicação precisar autenticar no banco, faltariam DB_USER e DB_PASSWORD.
- O DB_HOST precisa ser postgres dentro da rede Docker, e não localhost. Se o .env estiver configurado como localhost, a API não conseguirá acessar o PostgreSQL pelo container.
- O REDIS_HOST também deve ser redis dentro do Docker Compose, caso a aplicação esteja tentando acessar o Redis pelo nome do serviço.
- Não há volume para o Redis. Isso pode ser aceitável para um cache, mas significa que qualquer dado armazenado nele será perdido quando o container for recriado.
- Não há configuração de limites de recursos, como CPU e memória. Em um ambiente de produção, isso pode ser importante para evitar que um container consuma recursos excessivos.
- Não há Dockerfile apresentado, apesar de a API depender dele para ser construída. Não é possível verificar se o build está correto apenas pelo docker-compose.yml.
- Não há configuração de env_file, embora o comentário diga que as variáveis sensíveis são lidas do .env. O Compose consegue interpolar ${VAR} automaticamente a partir do .env, então isso não é necessariamente um erro, mas poderia ser explicado melhor.
- O uso de container_name reduz a flexibilidade do Compose. Em projetos simples funciona, mas geralmente não é necessário e pode dificultar cenários com múltiplas instâncias do mesmo serviço.
- Não há política de segurança adicional para o PostgreSQL e Redis. Por exemplo, não há restrição explícita de exposição dessas portas ao host — embora, positivamente, elas nem estejam expostas, ficando acessíveis apenas pela rede interna do Compose.
- Não há healthcheck para a própria API. PostgreSQL e Redis possuem verificação de saúde, mas não existe uma forma definida de verificar se a API está realmente funcionando.
- Não há configuração de command ou entrypoint, caso o projeto precise executar alguma etapa específica ao iniciar, como migrations.
- Não há configuração de migrations ou inicialização do banco. Se a aplicação depender da criação automática de tabelas, isso não está contemplado.
- Não há secrets do Docker ou outra estratégia mais segura para produção. O .env é adequado para desenvolvimento, mas não é necessariamente a melhor solução para gerenciamento de segredos em produção.
- Não há configuração específica para desenvolvimento, como bind mount do código-fonte ou nodemon. Isso significa que alterações no código provavelmente exigirão reconstruir a imagem.

## Minha Avaliação

- **Tempo economizado usando IA:** [estimativa em minutos]
- **Tempo gasto validando/corrigindo:** [estimativa em minutos]
- **Nota para o output da IA (1-10):** 
- **Usaria novamente para este tipo de tarefa?** [sim/não e por quê]