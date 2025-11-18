import Fastify from 'fastify';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import healthRoutes from './routes/health.js';
import userRoutes from './routes/users.js';
import createOrderRoutes from './routes/orders.js';
import loggerPlugin from './plugins/logger.js';

const app = Fastify({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname',
      },
    },
  },
});

app.register(swagger, {
  swagger: {
    info: { title: 'Order API', version: '1.0.0' },
  },
});

app.register(swaggerUi, {
  routePrefix: '/docs',
});

app.register(loggerPlugin);
app.register(healthRoutes);
app.register(userRoutes);
app.register(createOrderRoutes);

app.listen({ port: 3000, host: '0.0.0.0' }).then(() => {
  app.log.info('Server listening on port 3000');
});
