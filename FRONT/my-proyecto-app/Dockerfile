# Fase de construcción
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration=production

# Fase de producción
FROM node:22-alpine
WORKDIR /app

# Instala http-server para servir la app
RUN npm install -g http-server

# CORRECCIÓN: Copia toda la carpeta dist (sin /browser)
COPY --from=builder /app/dist/my-proyecto-app ./dist

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=4000
EXPOSE 4000

# Comando para servir la app (corregido)
CMD ["http-server", "dist", "-p", "4000", "--proxy", "http://0.0.0.0:4000?"]