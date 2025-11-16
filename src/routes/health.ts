import type { FastifyPluginAsync } from 'fastify';

const healthRoutes: FastifyPluginAsync = async (app) => {
  app.get('/healthz', async () => {
    return { status: 'ok' };
  });
};

export default healthRoutes;
