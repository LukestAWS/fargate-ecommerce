# Stage 2: Runner
FROM node:20-alpine
WORKDIR /app

# 1. Copy the standalone build (The actual server code)
# Notice the path now matches your folder structure: .next/standalone/frontend
COPY --from=builder /app/.next/standalone/frontend ./
COPY --from=builder /app/.next/standalone/node_modules ./node_modules

# 2. Copy static files (standalone doesn't include these by default)
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["node", "server.js"]
