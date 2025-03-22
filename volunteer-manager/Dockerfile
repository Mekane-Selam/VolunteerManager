# LOCATION: Place this file in the root directory of your Next.js application

# Use Node.js LTS
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci

# Copy all files
COPY . .

# Build application (including Tailwind CSS processing)
RUN npm run build

# Production image
FROM node:18-alpine AS runner
WORKDIR /app

# Set environment to production
ENV NODE_ENV=production

# Copy necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/standalone ./

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "server.js"]