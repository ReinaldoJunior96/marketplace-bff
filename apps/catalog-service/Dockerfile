FROM node:24-alpine

WORKDIR /workspace

COPY package.json package-lock.json ./
COPY apps/catalog-service/package.json ./apps/catalog-service/package.json

RUN npm ci --workspace=catalog-service

COPY apps/catalog-service ./apps/catalog-service

WORKDIR /workspace/apps/catalog-service

EXPOSE 3003

CMD ["npm", "run", "start:dev"]
