import type { FastifyPluginAsync } from 'fastify';
import fp from 'fastify-plugin';

const loggerPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.log.info('Logger plugin registered');
};

export default fp(loggerPlugin);
