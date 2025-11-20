FROM node:18-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Prisma generate doesn't need a real database connection, just a valid URL format
ENV DATABASE_URL="postgresql://placeholder:placeholder@localhost:5432/placeholder"
RUN npx prisma generate

FROM node:18-slim AS prod
WORKDIR /app
COPY --from=build /app/package*.json ./
RUN npm install --only=prod
COPY --from=build /app/src ./src
RUN mkdir -p dist && cp -r src/. dist/
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/view-dlq.js ./view-dlq.js
COPY --from=build /app/init-topics.js ./init-topics.js


# CMD is now defined in docker-compose.yml

