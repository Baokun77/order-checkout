import type { FastifyPluginAsync } from 'fastify';
import { prisma } from '../db/client.js';

const userRoutes: FastifyPluginAsync = async (app) => {
  app.get('/', async () => {
    return { message: 'hello world' };
  });

  app.post('/users', async () => {
    const user = await prisma.user.create({
      data: { email: 'test@example.com' },
    });
    return user;
  });
};

export default userRoutes;
