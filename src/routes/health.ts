import type { FastifyPluginAsync } from 'fastify';

const healthRoutes: FastifyPluginAsync = async (app) => {
  app.get(
    '/healthz',
    {
      schema: {
        description: 'Health check endpoint',
        tags: ['health'],
        response: {
          200: {
            type: 'object',
            properties: {
              status: { type: 'string', example: 'ok' },
            },
          },
        },
      },
    },
    async () => {
      return { status: 'ok' };
    }
  );
};

export default healthRoutes;
