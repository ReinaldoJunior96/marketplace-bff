FROM node:24-alpine

WORKDIR /workspace

COPY package.json package-lock.json ./
COPY apps/audit-service/package.json ./apps/audit-service/package.json

RUN npm ci --workspace=audit-service

COPY apps/audit-service ./apps/audit-service

WORKDIR /workspace/apps/audit-service

EXPOSE 3002

CMD ["npm", "run", "start:dev"]
