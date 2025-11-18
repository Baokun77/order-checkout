import Fastify from 'fastify';
import healthRoutes from './routes/health.js';
import userRoutes from './routes/users.js';
import createOrderRoutes from './routes/create_order.js';
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

app.register(loggerPlugin);
app.register(healthRoutes);
app.register(userRoutes);
app.register(createOrderRoutes);

app.listen({ port: 3000, host: '0.0.0.0' }).then(() => {
  app.log.info('Server listening on port 3000');
});
