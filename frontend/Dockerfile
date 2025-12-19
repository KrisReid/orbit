# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --silent

# Copy source code
COPY . .

# Build arguments for environment configuration
ARG VITE_API_URL=/api/v1
ENV VITE_API_URL=$VITE_API_URL

# Build the application (vite build only, type checking done in CI)
RUN npm run build:docker

# Production stage
FROM nginx:alpine

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Add healthcheck (use 127.0.0.1 to force IPv4, avoid IPv6 issues)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1/health || exit 1

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
