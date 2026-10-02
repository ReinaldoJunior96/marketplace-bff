import { HealthController } from './health.controller.js';
import type { RabbitMqConsumer } from './messaging/rabbitmq.consumer.js';
import type { RabbitMqPublisher } from './messaging/rabbitmq.publisher.js';

describe('HealthController', () => {
  it('reports liveness independently from RabbitMQ', () => {
    const controller = createController(false, false);

    expect(controller.getLiveness()).toEqual({ status: 'live' });
  });

  it('reports readiness only when consumer and publisher are connected', () => {
    const readyResponse = { status: vi.fn() };
    const readyController = createController(true, true);
    const unavailableResponse = { status: vi.fn() };
    const unavailableController = createController(true, false);

    expect(readyController.getReadiness(readyResponse)).toEqual({
      status: 'ready',
      dependencies: { rabbitmq: 'up' },
    });
    expect(readyResponse.status).not.toHaveBeenCalled();
    expect(unavailableController.getReadiness(unavailableResponse)).toEqual({
      status: 'not_ready',
      dependencies: { rabbitmq: 'down' },
    });
    expect(unavailableResponse.status).toHaveBeenCalledWith(503);
  });
});

function createController(
  consumerReady: boolean,
  publisherReady: boolean,
): HealthController {
  return new HealthController(
    { isReady: () => consumerReady } as RabbitMqConsumer,
    { isReady: () => publisherReady } as RabbitMqPublisher,
  );
}
