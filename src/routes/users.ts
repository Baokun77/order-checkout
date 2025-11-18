import type { FastifyPluginAsync } from 'fastify';
import { prisma } from '../db/client.js';

const userRoutes: FastifyPluginAsync = async (app) => {
  app.get(
    '/',
    {
      schema: {
        description: 'Hello World endpoint',
        tags: ['general'],
        response: {
          200: {
            type: 'object',
            properties: {
              message: { type: 'string', example: 'hello world' },
            },
          },
        },
      },
    },
    async () => {
      return { message: 'hello world' };
    }
  );

  app.post(
    '/users',
    {
      schema: {
        description: 'Create a new user',
        tags: ['users'],
        body: {
          type: 'object',
          required: ['email'],
          properties: {
            email: { type: 'string', format: 'email', description: 'User email address' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              id: { type: 'number' },
              email: { type: 'string' },
              createdAt: { type: 'string' },
            },
          },
        },
      },
    },
    async (req) => {
      const { email } = req.body as { email: string };
      const user = await prisma.user.create({
        data: { email },
      });
      return user;
    }
  );

  app.get<{ Params: { id: string } }>(
    '/users/:id/orders',
    {
      schema: {
        description: 'List all orders for a specific user',
        tags: ['users'],
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', description: 'User ID' },
          },
        },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'number' },
                createdAt: { type: 'string' },
                userId: { type: 'number' },
                items: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'number' },
                      name: { type: 'string' },
                      price: { type: 'string' },
                      quantity: { type: 'number' },
                      orderId: { type: 'number' },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    async (req) => {
      return prisma.order.findMany({
        where: { userId: Number(req.params.id) },
        include: { items: true },
        orderBy: { createdAt: 'desc' },
      });
    }
  );
};

export default userRoutes;
