# =========================
# 🏗️ Fase de construcción
# =========================
FROM node:22-alpine AS builder

WORKDIR /app

# Copia solo los archivos necesarios para instalar dependencias
COPY package.json package-lock.json ./

# Instala dependencias de manera limpia
RUN npm ci

# Copia el resto del código fuente
COPY . .

# 🚀 Aumentamos el límite de memoria para el build de Angular
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build -- --configuration=production


# =========================
# 🚀 Fase de producción
# =========================
FROM node:22-alpine

WORKDIR /app

# Instala servidor estático liviano
RUN npm install -g http-server

# Copia los archivos compilados desde la fase anterior
COPY --from=builder /app/dist/my-proyecto-app ./dist

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=4000
EXPOSE 4000

# Servir la aplicación Angular
CMD ["http-server", "dist", "-p", "4000", "--proxy", "http://0.0.0.0:4000?"]
