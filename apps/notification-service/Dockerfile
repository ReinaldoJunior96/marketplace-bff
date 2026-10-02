FROM node:24-alpine

WORKDIR /workspace

COPY package.json package-lock.json ./
COPY apps/notification-service/package.json ./apps/notification-service/package.json

RUN npm ci --workspace=notification-service

COPY apps/notification-service ./apps/notification-service

WORKDIR /workspace/apps/notification-service

EXPOSE 3004

CMD ["npm", "run", "start:dev"]
