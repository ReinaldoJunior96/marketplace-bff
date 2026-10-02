FROM node:24-alpine

WORKDIR /workspace

COPY package.json package-lock.json ./
COPY apps/order-service/package.json ./apps/order-service/package.json

RUN npm ci --workspace=order-service

COPY apps/order-service ./apps/order-service

WORKDIR /workspace/apps/order-service

EXPOSE 3001

CMD ["npm", "run", "start:dev"]
