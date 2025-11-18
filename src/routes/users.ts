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

  app.get<{ Params: { id: string } }>('/users/:id/orders', async (req) => {
    return prisma.order.findMany({
      where: { userId: Number(req.params.id) },
      include: { items: true },
    });
  });
};

export default userRoutes;
