import type { FastifyPluginAsync } from 'fastify';
import { prisma } from '../db/client.js';

const orderRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    '/orders',
    {
      schema: {
        description: 'Create a new order with items',
        tags: ['orders'],
        body: {
          type: 'object',
          required: ['userId', 'items'],
          properties: {
            userId: { type: 'number', description: 'User ID' },
            items: {
              type: 'array',
              description: 'Order items',
              items: {
                type: 'object',
                required: ['name', 'price', 'quantity'],
                properties: {
                  name: { type: 'string', description: 'Item name' },
                  price: { type: 'number', description: 'Item price' },
                  quantity: { type: 'number', description: 'Item quantity' },
                },
              },
            },
          },
        },
        response: {
          200: {
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

        return tx.order.findUnique({
          where: { id: order.id },
          include: { items: true },
        });
      });

      return result;
    }
  );

  app.get(
    '/orders',
    {
      schema: {
        description: 'List all orders',
        tags: ['orders'],
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
    async () => {
      return prisma.order.findMany({
        include: { items: true },
        orderBy: { createdAt: 'desc' },
      });
    }
  );

  app.get<{ Params: { id: string } }>(
    '/orders/:id',
    {
      schema: {
        description: 'Get order detail by ID',
        tags: ['orders'],
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', description: 'Order ID' },
          },
        },
        response: {
          200: {
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
    async (req) => {
      const order = await prisma.order.findUnique({
        where: { id: Number(req.params.id) },
        include: { items: true },
      });

      if (!order) {
        const error = new Error('Order not found') as Error & { statusCode: number };
        error.statusCode = 404;
        throw error;
      }

      return order;
    }
  );
};

export default orderRoutes;
