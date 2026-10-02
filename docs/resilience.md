# Testes de resiliência

Este guia assume o ambiente iniciado com:

```bash
docker compose up --build -d
docker compose ps
```

Use um `x-correlation-id` diferente em cada rodada para separar os logs.

## 1. Catalog Service indisponível

```bash
docker compose stop catalog-service

for attempt in 1 2 3 4; do
  curl -i http://localhost:3000/api/web/home \
    -H "x-correlation-id: catalog-failure-001"
done

docker compose logs bff | grep -E "catalog-service|circuit"
```

As respostas devem usar HTTP 503 e conter o contrato padronizado e o mesmo `correlationId`. Os logs devem mostrar retries limitados e, após o limiar, `circuit opened`. Nenhuma resposta deve expor hostname interno, stack ou erro de socket.

Recupere o catálogo e espere o reset configurado do circuit breaker:

```bash
docker compose start catalog-service
sleep 6

curl -i http://localhost:3000/api/web/home \
  -H "x-correlation-id: catalog-recovery-001"

docker compose logs bff | grep -E "half-open|closed"
```

## 2. Order Service indisponível

```bash
docker compose stop order-service

curl -i -X POST http://localhost:3000/api/web/orders \
  -H "Content-Type: application/json" \
  -H "x-correlation-id: order-failure-001" \
  -d '{
    "customerId": "customer-123",
    "items": [{ "productId": "product-001", "quantity": 1 }]
  }'

docker compose logs bff | grep -E "order-service|order-failure-001"
docker compose start order-service
```

O POST deve retornar erro controlado com `order-failure-001`. O log deve mostrar apenas `attempt: 1`: criação de pedido não possui retry automático porque ainda não há idempotência HTTP.

## 3. Retry e DLQ do Notification Service

Ative a falha somente para um `eventId` conhecido e somente no container de desenvolvimento:

```bash
NOTIFICATION_DEV_FAIL_EVENT_ID=resilience-dlq-001 \
  docker compose up -d --force-recreate notification-service

docker compose exec -T order-service node --input-type=module -e "
  import amqp from 'amqplib';
  const connection = await amqp.connect(process.env.RABBITMQ_URL);
  const channel = await connection.createConfirmChannel();
  await channel.assertExchange('marketplace.events', 'topic', { durable: true });
  const event = {
    eventId: 'resilience-dlq-001',
    eventType: 'order.created',
    occurredAt: new Date().toISOString(),
    correlationId: 'dlq-test-001',
    data: {
      orderId: 'order-dlq-001',
      customerId: 'customer-123',
      items: [{ productId: 'product-001', quantity: 1 }],
      status: 'CREATED'
    }
  };
  channel.publish('marketplace.events', 'order.created', Buffer.from(JSON.stringify(event)), {
    persistent: true,
    contentType: 'application/json',
    type: event.eventType,
    messageId: event.eventId,
    correlationId: event.correlationId
  });
  await channel.waitForConfirms();
  await channel.close();
  await connection.close();
"

sleep 5
docker compose logs notification-service | grep -E "dlq-test-001|scheduled for retry|dead letter"
docker compose exec rabbitmq rabbitmqctl list_queues name messages | grep notification.order-events
```

Devem ocorrer três processamentos no total, seguidos por uma mensagem em `notification.order-events.dlq`. A mensagem também pode ser inspecionada em `http://localhost:15672`.

Desative a simulação:

```bash
docker compose up -d --force-recreate notification-service
```

## 4. Evento duplicado

Publique duas vezes o mesmo evento mudando, no script anterior:

```text
eventId: idempotency-test-001
correlationId: idempotency-test-001
```

Execute o comando de publicação duas vezes e confira:

```bash
docker compose logs notification-service audit-service | grep -E "idempotency-test-001|Duplicate event ignored"
curl http://localhost:3002/logs/idempotency-test-001
```

O segundo `order.created` deve receber ACK sem repetir notificação nem registro de auditoria. Reiniciar o consumer apaga esse histórico, pois a idempotência ainda é mantida em memória.

## 5. RabbitMQ indisponível

```bash
docker compose stop rabbitmq

curl -i http://localhost:3001/health/live
curl -i http://localhost:3001/health/ready
curl -i http://localhost:3002/health/live
curl -i http://localhost:3002/health/ready
docker compose exec -T notification-service node -e \
  "fetch('http://localhost:3004/health/ready').then(async r => { console.log(r.status, await r.text()) })"
```

Liveness deve continuar HTTP 200 enquanto readiness passa para HTTP 503 com `rabbitmq: down`.

As conexões AMQP atuais não fazem reconexão automática. Depois de subir o broker, reinicie os serviços dependentes e confirme a recuperação:

```bash
docker compose start rabbitmq
docker compose restart order-service notification-service audit-service

curl -i http://localhost:3001/health/ready
curl -i http://localhost:3002/health/ready
docker compose ps
```

## Limitações atuais

- Idempotência é local e em memória; reinício ou múltiplas réplicas perdem essa garantia.
- Order Service ainda não possui idempotência HTTP, portanto `POST /orders` não usa retry.
- Publicação e persistência não usam Outbox Pattern.
- Consumers precisam ser reiniciados depois de uma queda completa do RabbitMQ.
- DLQs exigem inspeção e reprocessamento operacional manual.
