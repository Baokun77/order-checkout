import type { FastifyPluginAsync } from 'fastify';
import { prisma } from '../db/client.js';

const createOrderRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    '/orders',
    {
      schema: {
        body: {
          type: 'object',
          required: ['userId', 'items'],
          properties: {
            userId: { type: 'number' },
            items: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  name: { type: 'string' },
                  price: { type: 'number' },
                  quantity: { type: 'number' },
                },
              },
            },
          },
        },
      },
    },
    async (req) => {
      const { userId, items } = req.body as {
        userId: number;
        items: Array<{ name: string; price: number; quantity: number }>;
      };

      const result = await prisma.$transaction(async (tx) => {
        const order = await tx.order.create({
          data: { userId },
        });

        await tx.orderItem.createMany({
          data: items.map((i) => ({
            orderId: order.id,
            name: i.name,
            price: i.price,
            quantity: i.quantity,
          })),
        });

        return order;
      });

      return result;
    }
  );
};

export default createOrderRoutes;
