FROM node:18-slim AS build
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build

FROM node:18-slim AS prod
WORKDIR /app
COPY --from=build /app/package*.json .
RUN npm install --only=prod
COPY --from=build /app/dist ./dist

CMD ["node", "dist/index.js"]
