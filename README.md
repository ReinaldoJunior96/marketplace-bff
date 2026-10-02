# marketplace-bff

Este projeto será o Backend for Frontend de um marketplace.

Ele será construído com Node.js, TypeScript, NestJS e Docker. Os serviços serão executados de forma independente.

O primeiro componente criado foi o Marketplace BFF, localizado em `apps/bff`.

## Technical decisions

O BFF usa Fastify como adapter HTTP por oferecer bom desempenho e baixo overhead. O trade-off é trabalhar com um ecossistema menor e com menos compatibilidade de middlewares do que o Express.

Cada serviço será executado em seu próprio container. Isso representa melhor uma arquitetura distribuída e permite que cada serviço tenha seu próprio ciclo de execução. O trade-off é mais isolamento e independência em troca de maior complexidade de infraestrutura.

## Running the BFF with Docker

Inicie o ambiente a partir da raiz do projeto:

```sh
docker compose up --build
```

O endpoint inicial estará disponível em `http://localhost:3000`.

Para executar sem Compose, construa e inicie o container manualmente:

```sh
docker build -f apps/bff/Dockerfile -t marketplace-bff .
docker run --rm -p 3000:3000 marketplace-bff
```

## Order Service

Pedidos pertencem ao Order Service, não ao BFF. O serviço expõe `POST /orders`, `GET /orders/:id` e `GET /health` na porta 3001.

O armazenamento é mantido em memória para preservar o foco atual na arquitetura de comunicação. Os pedidos são perdidos quando o container reinicia. A persistência será tratada separadamente quando fizer sentido para o objetivo do projeto.

## Catalog Service

O Catalog Service fornece os produtos usados pela demonstração do marketplace. Ele é somente leitura e expõe `GET /products`, `GET /products/:id` e `GET /health` na porta 3003.

Os produtos ficam em memória para deixar o projeto simples e rápido de executar. O trade-off é que os dados não são persistentes e essa abordagem não é adequada para múltiplas instâncias do serviço.

O BFF não é dono do catálogo. Ele consome o Catalog Service por HTTP e expõe temporariamente `GET /api/catalog/products` e `GET /api/catalog/products/:id`. A integração usa `CATALOG_SERVICE_URL=http://catalog-service:3003` dentro da rede Docker. O BFF pode adaptar dados dos serviços downstream, mas não mantém uma cópia dos produtos.

O BFF também oferece contratos específicos para cada cliente:

```text
Catalog Service
      |
      v
Marketplace BFF
      +--> /api/web/home
      +--> /api/mobile/home
```

A Web recebe mais detalhes do produto. O Mobile recebe apenas `id`, `name`, `price` e `thumbnail`. Contratos específicos reduzem dados desnecessários e desacoplam os clientes dos serviços internos, mas aumentam a responsabilidade e a quantidade de contratos mantidos pelo BFF.

## Messaging

A criação de um pedido possui ações secundárias que não precisam bloquear a resposta HTTP. RabbitMQ será usado para distribuir esses eventos para consumidores independentes.

O producer publica uma mensagem. O exchange decide como roteá-la. A queue mantém a mensagem até que um consumer possa processá-la.

Mensageria reduz o acoplamento temporal entre serviços, mas adiciona infraestrutura, consistência eventual e novas situações de falha que precisam ser tratadas. A interface local de gerenciamento fica disponível em `http://localhost:15672`.

O fluxo atual é:

```text
Client
  |
  v
Order Service
  |
  +--> HTTP response
  |
  +--> RabbitMQ
          |
          order.created
```

O Order Service publica `order.created` na exchange `marketplace.events`. O HTTP confirma a criação, enquanto o evento permite que outros serviços reajam sem uma chamada direta.

A exchange é do tipo `topic` para permitir assinaturas futuras como `order.*` ou `order.created`. Uma exchange `direct` faria apenas correspondência exata. Uma `fanout` enviaria todos os eventos a todas as filas, ignorando a routing key. A flexibilidade de `topic` exige uma convenção clara para nomes e bindings.

Ainda não usamos Outbox Pattern. Se o pedido for salvo em memória e a publicação falhar, o estado e o evento ficam inconsistentes. Quando houver persistência, a Outbox poderá registrar a alteração e o evento na mesma transação.

## Notification Service

O Notification Service consome `order.created` pela queue `notification.order-events`. Por enquanto, o envio da notificação é apenas representado por um log. Depois do processamento, ele publica `notification.sent` na mesma exchange. O ACK da mensagem original ocorre somente após a confirmação dessa publicação.

```text
Client
  |
  v
Order Service
  |
  +--> HTTP response
  |
  +--> marketplace.events
          |
          order.created
          |
          v
  notification.order-events
          |
          v
  Notification Service
          |
          | notification.sent
          v
  marketplace.events
          |
          v
  audit.marketplace-events
```

O serviço possui sua própria queue para consumir o evento de forma independente de futuros consumers. Uma queue por consumer aumenta o isolamento e permite evolução independente, mas também aumenta o número de recursos e configurações no broker.

Um serviço pode ser consumer e producer ao mesmo tempo. Aqui, `order.created` é o fato de domínio que informa a criação do pedido. Depois de processar a notificação, o serviço publica `notification.sent`, que representa um novo fato ocorrido no fluxo. Os dois eventos mantêm o mesmo `correlationId`, mas possuem `eventId` diferentes.

Ainda não há Outbox Pattern. Se a notificação for processada e a publicação de `notification.sent` falhar, existe uma janela de inconsistência. Idempotência, retry e Outbox serão tratados separadamente.

Ainda não há retry ou DLQ. Se o processamento falhar, a mensagem é rejeitada sem voltar para a queue.

## Audit Service

O Audit Service é um consumer transversal usado para demonstrar rastreabilidade. Ele recebe os eventos da exchange `marketplace.events` pela queue própria `audit.marketplace-events` e expõe `GET /logs`, `GET /logs/:correlationId` e `GET /health` na porta 3002.

```text
Order Service
     |
     | order.created
     v
marketplace.events
     |
     +--> notification.order-events
     |         |
     |         v
     |   Notification Service
     |
     +--> audit.marketplace-events
               |
               v
           Audit Service
```

O binding `#` permite observar todos os eventos publicados na exchange sem alterar os producers. Isso facilita rastreabilidade e desacopla a auditoria dos serviços de domínio, mas aumenta o volume processado e exige atenção a filtros, retenção, escala e custo em um ambiente real.

Notification Service e Audit Service usam queues diferentes porque ambos precisam receber uma cópia do mesmo evento. Uma queue compartilhada distribuiria cada mensagem para apenas um dos consumers.

O log da aplicação informa o que o processo está fazendo. O registro de auditoria é o dado consultável mantido pelo serviço. Nesta etapa, esses registros ficam somente em memória e são perdidos quando o container reinicia.
