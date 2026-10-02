FROM node:24-alpine

WORKDIR /workspace

COPY package.json package-lock.json ./
COPY apps/bff/package.json ./apps/bff/package.json

RUN npm ci --workspace=bff

COPY apps/bff ./apps/bff

WORKDIR /workspace/apps/bff

EXPOSE 3000

CMD ["npm", "run", "start:dev"]
