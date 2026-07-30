# Multi-stage build: compile TypeScript + generate the Prisma client in a
# full node image, then run only the compiled output + prod deps in a slim
# runtime image.

FROM node:20-slim AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=build /app/dist ./dist
COPY prisma ./prisma

EXPOSE 4000
# Applies any pending migrations, then starts the server — safe to run on
# every deploy since `prisma migrate deploy` is a no-op when already current.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
