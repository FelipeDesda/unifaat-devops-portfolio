# ============================================
# Estágio 1: Dependências (builder)
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar apenas package files primeiro (aproveitar cache de layers)
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm ci --only=production && npm cache clean --force

# ============================================
# Estágio 2: Runtime (imagem final)
# ============================================
FROM node:20-alpine AS runtime

# Metadata da imagem (aponte para o SEU portfólio público)
LABEL org.opencontainers.image.source="https://github.com/SEU-USUARIO/unifaat-devops-portfolio"
LABEL org.opencontainers.image.description="TechNova API - Sistema de gestão de pedidos"

WORKDIR /app

# Criar usuário não-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S technova -u 1001 -G nodejs

# Copiar dependências do builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código da aplicação
COPY . .

# Usar usuário não-root
USER technova

# Expor porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Comando de execução
CMD ["node", "server.js"]