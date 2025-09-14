# Fase de construcción
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration=production

# Fase de producción
FROM node:18-alpine
WORKDIR /app

COPY --from=builder /app/package.json ./
COPY --from=builder /app/package-lock.json ./
RUN npm ci --omit=dev

# Estructura exacta que espera server.ts
COPY --from=builder /app/dist/my-project/browser ./browser
COPY --from=builder /app/dist/my-project/server ./server

ENV NODE_ENV=production
ENV PORT=4000
EXPOSE 4000

CMD ["node", "server/server.mjs"]