import 'dotenv/config';
import Fastify from 'fastify';
import client from 'prom-client';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import healthRoutes from './routes/health.js';
import userRoutes from './routes/users.js';
import orderRoutes from './routes/orders.js';
import loggerPlugin from './plugins/logger.js';
import { connectKafka, disconnectKafka } from './kafka/client.js';

const app = Fastify({
  logger: true,
});

const register = new client.Registry();
client.collectDefaultMetrics({ register });

app.register(swagger, {
  swagger: {
    info: { title: 'Order API', version: '1.0.0' },
    host: 'localhost:3000',
    schemes: ['http'],
    consumes: ['application/json'],
    produces: ['application/json'],
  },
});

app.register(swaggerUi, {
  routePrefix: '/doc',
});

app.register(loggerPlugin);
app.register(healthRoutes);
app.register(userRoutes);
app.register(orderRoutes);

app.get('/metrics', async () => {
  return register.metrics();
});

app.listen({ port: 3000, host: '0.0.0.0' }).then(async () => {
  app.log.info('Server listening on port 3000');
  await connectKafka();
});

app.addHook('onClose', async () => {
  await disconnectKafka();
});
