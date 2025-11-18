FROM node:18-slim AS build
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:18-slim AS prod
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/package*.json .
RUN npm install --only=prod
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma

CMD ["node", "dist/index.js"]
