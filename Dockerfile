# Multi-stage build for production
FROM node:18-alpine AS deps
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm ci

# Build stage
FROM node:18-alpine AS builder
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including devDependencies)
RUN npm ci

# Fix permissions for node_modules binaries
RUN chmod +x node_modules/.bin/*

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

# Expor porta padrão do Vite preview
EXPOSE 4173

# Comando para rodar o preview do Vite
CMD ["npm", "run", "preview"]
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json

# Create directories with proper permissions
RUN chown -R nextjs:nodejs /app
USER nextjs

EXPOSE 4173

ENV PORT=4173
ENV HOST=0.0.0.0

CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0"]
