# ==========================================
# Stage 1: Build
# ==========================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar apenas package files para aproveitar cache do Docker
COPY package*.json ./

# Instalar todas as dependências (incluindo dev)
RUN npm ci

# Copiar código fonte
COPY . .

# Executar lint e testes
RUN npm run lint
RUN npm run test:ci

# Build check
RUN npm run build

# ==========================================
# Stage 2: Production
# ==========================================
FROM node:18-alpine AS production

# Adicionar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copiar apenas package files
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar aplicação do stage builder
COPY --from=builder --chown=nodejs:nodejs /app/server.js ./

# Argumentos de build
ARG GITHUB_SHA
ENV GITHUB_SHA=${GITHUB_SHA}

# Variáveis de ambiente
ENV NODE_ENV=production \
    PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); });"

# Trocar para usuário não-root
USER nodejs

# Expor porta
EXPOSE 3000

# Start da aplicação
CMD ["node", "server.js"]
